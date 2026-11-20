# script/test_public_access_views.rb
# Run via: bin/rails runner script/test_public_access_views.rb

require "cgi"
require "securerandom"

puts "=== Testing PublicAccess Views & Lifecycle ==="

helpers = Rails.application.routes.url_helpers
original_forgery_setting = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false

begin
  ActiveRecord::Base.transaction do
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host!("localhost")
    rand_suffix = SecureRandom.hex(4)

    # 1. GET /public_access/new
    session.get(helpers.new_public_access_path, headers: { "Accept" => "text/html" })
    raise "Expected 200 OK on GET /public_access/new, got #{session.status}" unless session.status == 200
    raise "Expected public_access[label] input in form" unless session.response.body.include?("public_access[label]")
    raise "Expected public_access[access_scope] input in form" unless session.response.body.include?("public_access[access_scope]")
    puts "1. GET /public_access/new rendered (HTTP 200)."

    # 2. Guarded constraint: invalid POST returns 422 with error panel
    session.post(helpers.public_access_index_path, params: {
      public_access: { label: "", access_scope: "all_public" }
    }, headers: { "Accept" => "text/html" })
    raise "Expected 422 on invalid create, got #{session.status}" unless session.status == 422
    raise "Expected error panel on invalid create" unless session.response.body.include?("prevented saving")
    puts "2. Invalid POST /public_access rendered 422 error panel."

    # 3. Create active passes and verify GET /public_access summary + listing
    pass_a = PublicAccess.create!(label: "Curator Alpha #{rand_suffix}", access_scope: :all_public)
    pass_b = PublicAccess.create!(label: "Portfolio Beta #{rand_suffix}", access_scope: :portfolios_only)

    session.get(helpers.public_access_index_path, headers: { "Accept" => "text/html" })
    raise "Expected 200 OK on GET /public_access, got #{session.status}" unless session.status == 200
    decoded_body = CGI.unescapeHTML(session.response.body)

    raise "Expected summary labels in index view" unless decoded_body.include?("All public:") && decoded_body.include?("Portfolios only:") && decoded_body.include?("Exhibitions only:")
    raise "Expected pass_a label in listing" unless decoded_body.include?(pass_a.label)
    raise "Expected copy button payload for pass_a token" unless decoded_body.include?("navigator.clipboard.writeText('#{pass_a.token}')")
    raise "Expected revoke action for pass_a" unless decoded_body.include?(helpers.revoke_public_access_path(pass_a))
    puts "3. GET /public_access rendered summary card, copy button, and revoke action (HTTP 200)."

    # 4. GET /public_access/:id/edit
    session.get(helpers.edit_public_access_path(pass_a), headers: { "Accept" => "text/html" })
    raise "Expected 200 OK on GET /public_access/:id/edit, got #{session.status}" unless session.status == 200
    raise "Expected existing label in edit form" unless session.response.body.include?(pass_a.label)
    puts "4. GET /public_access/:id/edit rendered (HTTP 200)."

    # 5. Soft-revoke via PATCH and verify index hides copy/revoke buttons and shows Revoked badge
    session.patch(helpers.revoke_public_access_path(pass_a))
    raise "Expected 302 redirect on revoke, got #{session.status}" unless session.status == 302

    session.get(helpers.public_access_index_path, headers: { "Accept" => "text/html" })
    decoded_after = CGI.unescapeHTML(session.response.body)
    raise "Expected revoked pass to remain visible in audit listing" unless decoded_after.include?(pass_a.label)
    raise "Expected Revoked status pill for revoked pass" unless decoded_after.include?("Revoked")
    raise "Expected revoked token removed from copy button" if decoded_after.include?("navigator.clipboard.writeText('#{pass_a.token}')")
    raise "Expected active pass_b copy button to remain present" unless decoded_after.include?("navigator.clipboard.writeText('#{pass_b.token}')")
    puts "5. Soft-revoke audit listing state verified."

    raise ActiveRecord::Rollback
  end
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
end

puts "=== All PublicAccess View Tests Passed ==="

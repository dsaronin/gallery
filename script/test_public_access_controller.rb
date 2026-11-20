# script/test_public_access_controller.rb
# Run via: bin/rails runner script/test_public_access_controller.rb

require "securerandom"

puts "=== Testing PublicAccessController Routes & Actions ==="

helpers = Rails.application.routes.url_helpers

# 1. Verify route helpers and absence of destroy route
raise "Expected public_access_index_path to be /public_access" unless helpers.public_access_index_path == "/public_access"
raise "Expected new_public_access_path to be /public_access/new" unless helpers.new_public_access_path == "/public_access/new"
raise "Expected edit_public_access_path(1) to be /public_access/1/edit" unless helpers.edit_public_access_path(1) == "/public_access/1/edit"
raise "Expected revoke_public_access_path(1) to be /public_access/1/revoke" unless helpers.revoke_public_access_path(1) == "/public_access/1/revoke"
puts "1. Route generation helpers passed."

original_forgery_setting = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false

begin
  ActiveRecord::Base.transaction do
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host!("localhost")
    rand_suffix = SecureRandom.hex(4)

    # 2. POST /public_access (create)
    label = "Gallery Partner #{rand_suffix}"
    session.post(helpers.public_access_index_path, params: {
      public_access: {
        label: label,
        access_scope: "portfolios_only",
        expires_at: (Date.current + 30.days).to_s,
        notes: "Initial review pass"
      }
    })

    pass = PublicAccess.find_by!(label: label)
    raise "Expected 302 redirect on create, got #{session.status}" unless session.status == 302
    raise "Expected redirect to #{helpers.public_access_index_path}" unless session.response.location.end_with?(helpers.public_access_index_path)
    raise "Expected flash notice on create" unless session.flash[:notice].to_s.include?(label)
    raise "Expected 22-char token on create" unless pass.token.is_a?(String) && pass.token.length == 22
    raise "Expected portfolios_only scope" unless pass.portfolios_only?
    puts "2. POST /public_access (create) passed."

    # 3. PATCH /public_access/:id (update)
    updated_label = "#{label} Updated"
    session.patch(helpers.public_access_path(pass), params: {
      public_access: {
        label: updated_label,
        access_scope: "exhibitions_only",
        notes: "Updated scope"
      }
    })

    pass.reload
    raise "Expected 302 redirect on update, got #{session.status}" unless session.status == 302
    raise "Expected label updated" unless pass.label == updated_label
    raise "Expected exhibitions_only scope" unless pass.exhibitions_only?
    puts "4. PATCH /public_access/:id (update) passed."

    # 5. PATCH /public_access/:id/revoke (soft-revoke preserves record)
    session.patch(helpers.revoke_public_access_path(pass))
    pass.reload
    raise "Expected 302 redirect on revoke, got #{session.status}" unless session.status == 302
    raise "Expected redirect to #{helpers.public_access_index_path}" unless session.response.location.end_with?(helpers.public_access_index_path)
    raise "Expected record to still exist after soft-revoke" unless PublicAccess.exists?(pass.id)
    raise "Expected revoked? true after revoke" unless pass.revoked?
    raise "Expected flash notice on revoke" unless session.flash[:notice].to_s.include?("revoked")
    puts "5. PATCH /public_access/:id/revoke (soft-revoke) passed."

    # 6. Guarded constraint: DELETE /public_access/:id is not routed (404)
    session.delete("/public_access/#{pass.id}")
    raise "Expected 404 on unrouted DELETE /public_access/:id, got #{session.status}" unless session.status == 404
    raise "Expected record to remain persisted after DELETE attempt" unless PublicAccess.exists?(pass.id)
    puts "6. Guarded absence of DELETE route (HTTP 404) passed."

    # 7. Missing record rescue
    session.patch(helpers.revoke_public_access_path(999_999_999))
    raise "Expected 302 redirect on missing record, got #{session.status}" unless session.status == 302
    raise "Expected flash alert on missing record" unless session.flash[:alert].to_s.include?("not found")
    puts "7. Missing record rescue passed."

    raise ActiveRecord::Rollback
  end
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
end

puts "=== All PublicAccessController Tests Passed ==="

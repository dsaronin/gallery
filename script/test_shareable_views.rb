# script/test_shareable_views.rb
# Run via: bin/rails runner script/test_shareable_views.rb

require "securerandom"
require "cgi"
require "securerandom"

puts "=== Testing Shareable Card Views (Portfolio & Exhibition) ==="

helpers = Rails.application.routes.url_helpers

def verify_card_view_flow(session, helpers, record, resource_key, removed_label)
  label             = record.class.name
  index_path        = helpers.public_send("#{resource_key}_index_path")
  make_public_path  = helpers.public_send("make_public_#{resource_key}_path", record)
  make_private_path = helpers.public_send("make_private_#{resource_key}_path", record)

  # 1. Private state rendering
  session.get(index_path, headers: { "Accept" => "text/html" })
  raise "#{label}: expected 200 OK on GET #{index_path}, got #{session.status}" unless session.status == 200
  body = session.response.body

  raise "#{label}: expected replaced telemetry label '#{removed_label}' to be absent" if body.include?(removed_label)
  raise "#{label}: expected 'Share:' row on card" unless body.include?("Share:")
  raise "#{label}: expected Make Public action (#{make_public_path}) when private" unless body.include?(make_public_path)
  raise "#{label}: expected Make Private action (#{make_private_path}) to be absent when private" if body.include?(make_private_path)
  raise "#{label}: expected subdued 'private' indicator when private" unless body.include?("private")

  # 2. Publish via PATCH and verify public state rendering
  session.patch(make_public_path)
  record.reload
  token = record.share_token
  raise "#{label}: expected non-blank share_token after make_public" if token.blank?

  session.get(index_path, headers: { "Accept" => "text/html" })
  raise "#{label}: expected 200 OK on GET #{index_path} after publish" unless session.status == 200
  body = session.response.body
  decoded_body = CGI.unescapeHTML(body)

  raise "#{label}: expected Make Private action (#{make_private_path}) when public" unless body.include?(make_private_path)
  raise "#{label}: expected Make Public action (#{make_public_path}) to be absent when public" if body.include?(make_public_path)
  raise "#{label}: expected copy button with share_token payload" unless decoded_body.include?("navigator.clipboard.writeText('#{token}')")

  # 3. Revert to private via PATCH and verify token removed from view
  session.patch(make_private_path)
  record.reload

  session.get(index_path, headers: { "Accept" => "text/html" })
  body = session.response.body
  decoded_body = CGI.unescapeHTML(body)
  raise "#{label}: expected Make Public action restored after make_private" unless body.include?(make_public_path)
  raise "#{label}: expected revoked token absent from clipboard button" if decoded_body.include?("navigator.clipboard.writeText('#{token}')")

  puts "  [PASS] #{label} index card shareable view states verified."
end

original_forgery_setting = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false

begin
  ActiveRecord::Base.transaction do
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host!("localhost")
    rand_suffix = SecureRandom.hex(4)

    portfolio  = Portfolio.create!(name: "view_share_#{rand_suffix}", title: "View Share Portfolio #{rand_suffix}")
    exhibition = Exhibition.create!(title: "View Share Exhibition #{rand_suffix}")

    verify_card_view_flow(session, helpers, portfolio, :portfolio, "<dt>Likes:</dt>")
    verify_card_view_flow(session, helpers, exhibition, :exhibition, "<dt>Sales policy:</dt>")

    raise ActiveRecord::Rollback
  end
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
end

puts "=== All Shareable View Tests Passed ==="

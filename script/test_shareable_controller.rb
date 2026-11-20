# script/test_shareable_controller.rb
# Run via: bin/rails runner script/test_shareable_controller.rb

require "securerandom"

puts "=== Testing CollectionShareable Routes & Controller Actions ==="

helpers = Rails.application.routes.url_helpers

# 1. Verify route helpers
raise "Expected make_public_portfolio_path(1) to be /portfolio/1/make_public" unless helpers.make_public_portfolio_path(1) == "/portfolio/1/make_public"
raise "Expected make_private_portfolio_path(1) to be /portfolio/1/make_private" unless helpers.make_private_portfolio_path(1) == "/portfolio/1/make_private"
raise "Expected make_public_exhibition_path(1) to be /exhibition/1/make_public" unless helpers.make_public_exhibition_path(1) == "/exhibition/1/make_public"
raise "Expected make_private_exhibition_path(1) to be /exhibition/1/make_private" unless helpers.make_private_exhibition_path(1) == "/exhibition/1/make_private"
puts "1. Shareable route helpers passed."

def verify_controller_flow(session, helpers, record, resource_key)
  label = record.class.name
  index_path        = helpers.public_send("#{resource_key}_index_path")
  make_public_path  = helpers.public_send("make_public_#{resource_key}_path", record)
  make_private_path = helpers.public_send("make_private_#{resource_key}_path", record)
  missing_pub_path  = helpers.public_send("make_public_#{resource_key}_path", 999_999_999)
  missing_priv_path = helpers.public_send("make_private_#{resource_key}_path", 999_999_999)

  # Happy path: make_public
  session.patch(make_public_path)
  record.reload
  raise "#{label}: expected 302 on make_public, got #{session.status}" unless session.status == 302
  raise "#{label}: expected redirect to #{index_path}" unless session.response.location.end_with?(index_path)
  raise "#{label}: expected 22-char share_token" unless record.share_token.is_a?(String) && record.share_token.length == 22
  raise "#{label}: expected flash notice on make_public" unless session.flash[:notice].to_s.include?("is now public")

  # Idempotent make_public preserves token
  original_token = record.share_token
  session.patch(make_public_path)
  record.reload
  raise "#{label}: expected 302 on repeat make_public" unless session.status == 302
  raise "#{label}: expected share_token unchanged on repeat make_public" unless record.share_token == original_token

  # Happy path: make_private
  session.patch(make_private_path)
  record.reload
  raise "#{label}: expected 302 on make_private, got #{session.status}" unless session.status == 302
  raise "#{label}: expected redirect to #{index_path}" unless session.response.location.end_with?(index_path)
  raise "#{label}: expected share_token nil after make_private" unless record.share_token.nil?
  raise "#{label}: expected flash notice on make_private" unless session.flash[:notice].to_s.include?("is now private")

  # Idempotent make_private
  session.patch(make_private_path)
  record.reload
  raise "#{label}: expected 302 on repeat make_private" unless session.status == 302
  raise "#{label}: expected share_token to remain nil" unless record.share_token.nil?

  # Guarded constraint: missing record rescue
  [missing_pub_path, missing_priv_path].each do |path|
    session.patch(path)
    raise "#{label}: expected 302 on missing record (#{path}), got #{session.status}" unless session.status == 302
    raise "#{label}: expected flash alert on missing record" unless session.flash[:alert].to_s.include?("not found")
  end

  puts "  [PASS] #{label}Controller shareable actions verified."
end

original_forgery_setting = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false

begin
  ActiveRecord::Base.transaction do
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host!("localhost")
    rand_suffix = SecureRandom.hex(4)

    portfolio  = Portfolio.create!(name: "ctrl_share_#{rand_suffix}", title: "Ctrl Share Portfolio #{rand_suffix}")
    exhibition = Exhibition.create!(title: "Ctrl Share Exhibition #{rand_suffix}")

    verify_controller_flow(session, helpers, portfolio, :portfolio)
    verify_controller_flow(session, helpers, exhibition, :exhibition)

    raise ActiveRecord::Rollback
  end
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
end

puts "=== All CollectionShareable Controller Tests Passed ==="

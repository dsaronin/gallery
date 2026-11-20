# script/test_dashboard_views.rb
# Run via: bin/rails runner script/test_dashboard_views.rb

require "cgi"
require "securerandom"

puts "=== Testing Dashboard Cards (Venues & Showings + Admin) ==="

helpers = Rails.application.routes.url_helpers

ActiveRecord::Base.transaction do
  session = ActionDispatch::Integration::Session.new(Rails.application)
  session.host!("localhost")
  rand_suffix = SecureRandom.hex(4)

  # Seed an active pass and a revoked pass to verify active-only count
  active_pass  = PublicAccess.create!(label: "Dash Active #{rand_suffix}", access_scope: :all_public)
  revoked_pass = PublicAccess.create!(label: "Dash Revoked #{rand_suffix}", access_scope: :all_public)
  revoked_pass.revoke!

  expected_active = PublicAccess.active.count

  session.get(helpers.dashboard_path, headers: { "Accept" => "text/html" })
  raise "Expected 200 OK on GET /dashboard, got #{session.status}" unless session.status == 200
  body = CGI.unescapeHTML(session.response.body)

  # 1. Card 4: Venues & Showings title, venue telemetry line, and action ordering
  raise "Expected Card 4 title 'Venues & Showings'" unless body.include?("Venues & Showings")
  raise "Expected Venues telemetry line in dashboard" unless body.include?("-m wall)")
  raise "Expected 'Venues »' action link" unless body.include?("Venues »")
  raise "Expected 'Showings »' action link" unless body.include?("Showings »")
  raise "Expected 'Venues »' to appear before 'Showings »'" unless body.index("Venues »") < body.index("Showings »")
  puts "1. Card 4 (Venues & Showings) verified."

  # 2. Card 5: Admin title, active PublicAccess telemetry, Sharing action, and no Venue Continue link
  raise "Expected Card 5 title 'Admin'" unless body.include?("<h4 class='card-title'>Admin</h4>") || body.include?("<h4 class=\"card-title\">Admin</h4>")
  raise "Expected old 'Venue…' title to be absent" if body.include?("Venue…")
  raise "Expected public telemetry '#{expected_active} shareable'" unless body.include?("#{expected_active} shareable")
  raise "Expected 'Sharing »' action linking to #{helpers.public_access_index_path}" unless body.include?(helpers.public_access_index_path)
  puts "2. Card 5 (Admin) verified."

  raise ActiveRecord::Rollback
end

puts "=== All Dashboard View Tests Passed ==="

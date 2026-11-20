# script/test_health_check.rb
# Run via: bin/rails runner script/test_health_check.rb

puts "=== Testing /up Health Check Route ==="

helpers = Rails.application.routes.url_helpers

# 1. Verify named route helper
raise "Expected rails_health_check_path to be /up, got #{helpers.rails_health_check_path.inspect}" unless helpers.rails_health_check_path == "/up"
puts "1. Route helper rails_health_check_path => /up passed."

session = ActionDispatch::Integration::Session.new(Rails.application)
session.host!("localhost")

# 2. Happy path: GET /up returns HTTP 200
session.get("/up")
raise "Expected 200 for GET /up, got #{session.status}" unless session.status == 200
puts "2. Happy path GET /up returned 200."

# 3. Guarded constraint: POST /up is not routed (404)
original_forgery = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false
begin
  session.post("/up")
  raise "Expected 404 for POST /up, got #{session.status}" unless session.status == 404
  puts "3. Guarded constraint POST /up returned 404."
ensure
  ActionController::Base.allow_forgery_protection = original_forgery
end

puts "=== All Health Check Tests Passed ==="

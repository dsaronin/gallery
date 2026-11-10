# frozen_string_literal: true

# Usage: bin/rails runner script/test_curations_controller.rb

require "securerandom"

puts "==> Starting validation for CurationsController and routes..."

app = ActionDispatch::Integration::Session.new(Rails.application)
app.host = "localhost"
rand_suffix = SecureRandom.hex(4)

# 1. Verify route generation helpers
port_path = Rails.application.routes.url_helpers.portfolio_curation_path(portfolio_id: 1)
raise "Assertion failed: Portfolio curation path mismatch" unless port_path == "/portfolio/1/curation"
puts "  [PASS] Portfolio curation route matches: #{port_path}"

exhib_path = Rails.application.routes.url_helpers.exhibition_curation_path(exhibition_id: 2)
raise "Assertion failed: Exhibition curation path mismatch" unless exhib_path == "/exhibition/2/curation"
puts "  [PASS] Exhibition curation route matches: #{exhib_path}"

# 2. Integration check: GET /portfolio/:id/curation
portfolio = Portfolio.create!(
  name: "ctrl_port_#{rand_suffix}",
  title: "Controller Test Portfolio #{rand_suffix}"
)

curation_url = Rails.application.routes.url_helpers.portfolio_curation_path(portfolio_id: portfolio.id)
app.get curation_url, headers: { "Accept" => "text/html" }

unless app.response.successful?
  puts "  [FAIL DEBUG] Portfolio dispatch status: #{app.response.status}"
  # Action View error headline:
  if (h1 = app.response.body.match(/<h1[^>]*>(.*?)<\/h1>/m))
    puts "  [FAIL DEBUG] Headline: #{h1[1].gsub(/<[^>]+>/, '').strip}"
  end

  # Extract "undefined method `xyz' for ..."
  if (err = app.response.body.match(/(undefined method [`']?[^<\n\r]+)/i))
    puts "  [FAIL DEBUG] Method Error: #{err[1]}"
  end

  # Extract exact template and line number where failure occurred
  app.response.body.scan(/([a-zA-Z0-9_\/-]+\.html\.haml:\d+)/).flatten.uniq.each do |loc|
    puts "  [FAIL DEBUG] Template Line: #{loc}"
  end
end

raise "Assertion failed: GET #{curation_url} expected 200 OK" unless app.response.successful?
puts "  [PASS] Portfolio curation interface rendered (HTTP 200)."

# 3. Integration check: GET /exhibition/:id/curation
venue = Venue.create!(name: "Test Venue #{rand_suffix}")
exhibition = Exhibition.create!(
  title: "Controller Test Exhibition #{rand_suffix}",
  portfolio: portfolio,
  venue: venue
)

exhib_url = Rails.application.routes.url_helpers.exhibition_curation_path(exhibition_id: exhibition.id)
app.get exhib_url, headers: { "Accept" => "text/html" }

unless app.response.successful?
  puts "  [FAIL DEBUG] Exhibition dispatch status: #{app.response.status}"
  error_headline = app.response.body.match(/<h1[^>]*>(.*?)<\/h1>/m)&.[](1)&.strip
  puts "  [FAIL DEBUG] Headline: #{error_headline}" if error_headline
end

raise "Assertion failed: GET #{exhib_url} expected 200 OK" unless app.response.successful?
puts "  [PASS] Exhibition curation interface rendered (HTTP 200)."

# 4. Cleanup
exhibition.destroy!
venue.destroy!
portfolio.destroy!
puts "  [PASS] Temporary records cleaned up."

puts "==> All CurationsController routing and dispatch checks passed successfully!"

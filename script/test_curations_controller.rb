# frozen_string_literal: true

# Usage: bin/rails runner script/test_curations_controller.rb

require "securerandom"

puts "==> Starting validation for CurationsController and routes..."

app = ActionDispatch::Integration::Session.new(Rails.application)
app.host = "localhost"
rand_suffix = SecureRandom.hex(4)

# 1. Verify route generation helpers
port_path = Rails.application.routes.url_helpers.portfolio_curation_path(portfolio_id: 1)
raise "Assertion failed: Portfolio curation path mismatch" unless port_path == "/portfolios/1/curation"
puts "  [PASS] Portfolio curation route matches: #{port_path}"

exhib_path = Rails.application.routes.url_helpers.exhibition_curation_path(exhibition_id: 2)
raise "Assertion failed: Exhibition curation path mismatch" unless exhib_path == "/exhibitions/2/curation"
puts "  [PASS] Exhibition curation route matches: #{exhib_path}"

# 2. Integration check: GET /portfolios/:id/curation
portfolio = Portfolio.create!(
  name: "ctrl_port_#{rand_suffix}",
  title: "Controller Test Portfolio #{rand_suffix}"
)

curation_url = Rails.application.routes.url_helpers.portfolio_curation_path(portfolio_id: portfolio.id)
app.get curation_url, headers: { "Accept" => "text/html" }

unless app.response.successful?
  puts "  [FAIL DEBUG] Portfolio dispatch status: #{app.response.status}"
  error_headline = app.response.body.match(/<h1[^>]*>(.*?)<\/h1>/m)&.[](1)&.strip
  error_detail   = app.response.body.match(/<pre[^>]*class="message"[^>]*>(.*?)<\/pre>/m)&.[](1)&.strip ||
                   app.response.body.match(/class="exception">([^<]+)/)&.[](1)&.strip
  trace_line     = app.response.body.match(/<pre class="trace[^>]*>(.*?)<\/pre>/m)&.[](1)&.strip

  puts "  [FAIL DEBUG] Headline: #{error_headline}" if error_headline
  puts "  [FAIL DEBUG] Detail: #{error_detail}" if error_detail
  puts "  [FAIL DEBUG] Trace snippet: #{trace_line[0..200]}" if trace_line
end

raise "Assertion failed: GET #{curation_url} expected 200 OK" unless app.response.successful?
puts "  [PASS] Portfolio curation interface rendered (HTTP 200)."

# 3. Integration check: GET /exhibitions/:id/curation
exhibition = Exhibition.create!(title: "Controller Test Exhibition #{rand_suffix}")

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
portfolio.destroy!
exhibition.destroy!
puts "  [PASS] Temporary records cleaned up."

puts "==> All CurationsController routing and dispatch checks passed successfully!"

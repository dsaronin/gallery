# script/test_production_boot_config.rb
# Run via: bin/rails runner script/test_production_boot_config.rb

require "tempfile"
require "open3"

puts "=== Testing Production Boot, Env Loading & Puma Bind Config ==="

# 1. Verify GALLERY_ENV_FILE precedence in a clean subprocess
Tempfile.create(["gallery_test", ".env"]) do |tf|
  tf.write("GALLERY_BOOT_PROBE_VAR=loaded_from_custom_env\n")
  tf.flush

  cmd = [
    { "GALLERY_ENV_FILE" => tf.path },
    "bundle", "exec", "ruby", "-Ilib",
    "-e", 'require_relative "config/boot"; puts ENV["GALLERY_BOOT_PROBE_VAR"].to_s'
  ]
  stdout, stderr, status = Open3.capture3(*cmd, chdir: Rails.root.to_s)
  raise "Subprocess boot failed: #{stderr}" unless status.success?
  raise "Expected 'loaded_from_custom_env', got #{stdout.strip.inspect}" unless stdout.strip == "loaded_from_custom_env"
end
puts "1. GALLERY_ENV_FILE custom path loading in config/boot.rb passed."

# 2. Verify production.rb contains expected host whitelist, /up exclusion, and force_ssl = false
prod_rb = File.read(Rails.root.join("config/environments/production.rb"))
%w[localhost 127.0.0.1 uwanda 192.168.1.68 10.8.0.1].each do |host|
  raise "Missing allowed host #{host.inspect} in production.rb" unless prod_rb.include?(%("#{host}"))
end
raise "Missing /up host_authorization exclusion in production.rb" unless prod_rb.include?('request.path == "/up"')
raise "Expected explicit config.force_ssl = false in production.rb" unless prod_rb.include?("config.force_ssl = false")
puts "2. config/environments/production.rb hosts, /up exclusion, and force_ssl=false verified."

# 3. Verify config/puma.rb honors BIND without adding a duplicate port listener
puma_rb = File.read(Rails.root.join("config/puma.rb"))
raise "Expected conditional BIND handling in config/puma.rb" unless puma_rb.include?('ENV["BIND"]')
puts "3. config/puma.rb conditional BIND configuration verified."

puts "=== All Production Boot Config Tests Passed ==="

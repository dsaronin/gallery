ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# Load environment file from GALLERY_ENV_FILE if specified, 
#    falling back to local .env
custom_env = ENV["GALLERY_ENV_FILE"].to_s.strip
env_file   = custom_env.empty? ? File.expand_path("../.env", __dir__) : File.expand_path(custom_env)

if File.exist?(env_file)
  File.foreach(env_file) do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")
    key, val = line.split("=", 2)
    next unless key && val
    ENV[key.strip] ||= val.strip.gsub(/\A["']|["']\z/, "")
  end
end


require_relative "boot"
require_relative "../lib/gallery/environ"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Gallery
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.autoload_lib(ignore: %w[assets tasks])

    # Synchronize Rails configuration with Gallery::Environ
    env = Gallery::Environ.instance

# APPLICATION constants ... #TODO replace with config file?
    config.app_name     = env.app_name
    config.app_version  = env.app_version
    config.photo_path   = env.photo_path
    config.photo_base   = env.photo_base
    config.photo_source = env.photo_source

    config.public_file_server.enabled = true
 
  end   # class Application
end    # module Gallery

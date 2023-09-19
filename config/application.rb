require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Gallery
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

# APPLICATION constants ... #TODO replace with config file?
    config.app_name    = "Gallery"
    config.app_version =  "0.01"
    config.photo_path   = ( ENV["GALLERY_PATH"]  ||  ENV["HOME"]  || "/" )
    config.photo_base   = ( ENV["GALLERY_BASE"]   || "Pictures" )
    config.photo_source = ( ENV["GALLERY_SOURCE"]  || "darktable_exported" )

 
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end

# frozen_string_literal: true

require "gallery/environ"

Rails.application.config.before_initialize do
  # Autoload lib directory if not already configured
  Rails.autoloaders.main.ignore(Rails.root.join("lib/gallery/version.rb"))
end

Rails.application.config.after_initialize do
  Gallery::Environ.instance.setup_work
end

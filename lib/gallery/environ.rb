# Gallery: 
# Copyright (c) 2026 David S Anderson, All Rights Reserved
#
# class Environ -- sets up & control environment for application
# SINGLETON: invoke as Environ.instance
#
#----------------------------------------------------------
# requirements
#----------------------------------------------------------
  require_relative 'ansi_color'
  require 'singleton'
  require_relative 'version'
  
#----------------------------------------------------------
# +++++++++++++++++++++++++++++++++++++++++++++++++
module Gallery              # Define the top-level module  Gallery::
# +++++++++++++++++++++++++++++++++++++++++++++++++

class Environ
  include Singleton
  extend AnsiColor
  
#module constants

  APP_NAME = "GALLERY"
  APP_NAME_HEAD = "#{APP_NAME}: "

  attr_reader :photo_path, :photo_base, :photo_source, :target_pictures_path, :initialized_at, :app_name, :app_version

  #  ------------------------------------------------------------
  #  ------------------------------------------------------------
  #  ------------------------------------------------------------
  def initialize
    @app_name             = APP_NAME
    @app_version          = Gallery::VERSION
    @photo_path           = ENV["GALLERY_PATH"] || ENV["HOME"] || "/"
    @photo_base           = ENV["GALLERY_BASE"] || "Pictures"
    @photo_source         = ENV["GALLERY_SOURCE"] || "darktable_exported"
    @target_pictures_path = File.join(@photo_path, @photo_base)
    @initialized_at       = nil
  end

    def setup_work
      @initialized_at = Time.current
      self.class.log_info("#{APP_NAME} v#{Gallery::VERSION} environment initialized.")
      self.class.log_info("Target Pictures Path: #{@target_pictures_path}")

      unless File.directory?(@target_pictures_path)
        self.class.log_warn("Target directory does not exist or is unmounted: #{@target_pictures_path}")
      end
    end

    # --- Standard Logging Wrappers ---

    def self.logger
      Rails.logger || Logger.new($stderr)
    end

    def self.log_info(msg)
      formatted = wrap_cyan("#{APP_NAME_HEAD}#{msg}")
      logger.info(formatted)
    end

    def self.log_warn(msg)
      formatted = wrap_green_bold("#{APP_NAME_HEAD}#{msg}")
      logger.warn(formatted)
    end

    def self.log_error(msg)
      formatted = wrap_red_bold("#{APP_NAME_HEAD}#{msg}")
      logger.error(formatted)
    end

    def self.put_info(msg)
      $stdout.puts wrap_cyan("#{APP_NAME_HEAD}#{msg}")
    end

    def self.put_error(msg)
      $stderr.puts wrap_red_bold("#{APP_NAME_HEAD}#{msg}")
    end

    # Helper for inspect/status
    def to_s
      "#{APP_NAME} v#{Gallery::VERSION} [path: #{@target_pictures_path}]"
    end
  #  ------------------------------------------------------------
end  # Class Environ
  
end  # module Gallery

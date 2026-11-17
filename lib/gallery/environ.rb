# frozen_string_literal: true

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
  require 'securerandom'
  require_relative "curation_criteria"
  
#----------------------------------------------------------
# +++++++++++++++++++++++++++++++++++++++++++++++++
module Gallery              # Define the top-level module  Gallery::
# +++++++++++++++++++++++++++++++++++++++++++++++++

class Environ
  include Singleton
  extend AnsiColor

#----------------------------------------------------------
 # Subclasses and Domain Dictionaries
#----------------------------------------------------------
  require_relative 'environ/session_state'
  require_relative 'environ/cc_license'
  require_relative 'environ/placard_data'
  require_relative 'environ/dictionaries'
# +++++++++++++++++++++++++++++++++++++++++++++++++
# +++++++++++++++++++++++++++++++++++++++++++++++++

# +++++++++++++++++++++++++++++++++++++++++++++++++
#module constants
# +++++++++++++++++++++++++++++++++++++++++++++++++

  APP_NAME = "GALLERY"
  APP_NAME_HEAD = "#{APP_NAME}: "

# Application identity & attribution defaults
# Candidate Artist Name / Kanji pairs:
#   1. "Kishindo" / "気震"
#   2. "Kurobi"   / "黒火"
#   3. "Kageki"   / "影気"
  ARTIST_NAME       = "Kishindo".freeze
  ARTIST_NAME_KANJI = "気震".freeze
  ARTIST_BRAND      = "DARKFIRE".freeze

  DEFAULT_ARTIST_NAME   = ARTIST_NAME
  DEFAULT_PREP_DAYS     = 1
  DEFAULT_TEARDOWN_DAYS = 1

# Operational curation capacity bounds
    MAX_PORTFOLIO_SIZE  = 60
    MAX_EXHIBITION_SIZE = 40

# Physical wall placard paper dimensions & proportional scales (A6 / 4x6 baseline)
  DEFAULT_PLACARD_DISPLAY_MODE = :solo
  DEFAULT_PLACARD_PAPER_SIZE   = :a6

  PLACARD_PAPER_SIZES = {
    a6: { label: "4×6 (A6)", width: "6in",   height: "4in",   scale: 1.0   }.freeze,
    a5: { label: "A5",       width: "210mm", height: "148mm", scale: 1.414 }.freeze,
    a7: { label: "A7",       width: "105mm", height: "74mm",  scale: 0.707 }.freeze
  }.freeze
  #  ------------------------------------------------------------
  #  ------------------------------------------------------------
  attr_reader :photo_path, :photo_base, :photo_source, :photo_dotfile, :target_pictures_path, :initialized_at, :app_name, :app_version
  #  ------------------------------------------------------------

  #  ------------------------------------------------------------
  #  ------------------------------------------------------------
  def initialize
    @app_name             = APP_NAME
    @app_version          = Gallery::VERSION
    @photo_path           = ENV["GALLERY_PATH"] || ENV["HOME"] || "/"
    @photo_base           = ENV["GALLERY_BASE"] || "Pictures"
    @photo_source         = ENV["GALLERY_SOURCE"] || "darktable_exported"
    @photo_dotfile        = ENV["GALLERY_DOTFILE"] || ".gallery"
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

    # --- System & Security Utilities ---

    # returns a 22-char random string for sharing link
    def self.generate_token(bytes = 16)
      SecureRandom.urlsafe_base64(bytes)
    end
  #  ------------------------------------------------------------
end  # Class Environ
  
end  # module Gallery

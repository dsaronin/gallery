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
  
#----------------------------------------------------------
# +++++++++++++++++++++++++++++++++++++++++++++++++
module Gallery              # Define the top-level module  Gallery::
# +++++++++++++++++++++++++++++++++++++++++++++++++

class Environ
  include Singleton
  extend AnsiColor
  
# +++++++++++++++++++++++++++++++++++++++++++++++++
  # --- Nested Session State Container ---
  # This will maintain user state & preferences across sessions
  # ******************************************************
    class SessionState
      SESSION_KEY = :gallery_state

      attr_accessor :current_catalog_id, :current_category_id, 
                    :current_portfolio_id,
                    :current_exhibition_id,
                    :current_showing_id,
                    :current_tag_id

      def initialize(attrs = {})
        attrs = attrs.symbolize_keys if attrs.respond_to?(:symbolize_keys)
        attrs ||= {}

        @current_catalog_id = attrs[:current_catalog_id]
        @current_category_id = attrs[:current_category_id]
        @current_tag_id      = attrs[:current_tag_id]
        @current_portfolio_id  = attrs[:current_portfolio_id]
        @current_exhibition_id = attrs[:current_exhibition_id]
        @current_showing_id    = attrs[:current_showing_id]
      end

      # Hydrates state from the Rails session
      def self.load(session)
        raw = session[SESSION_KEY] || {}
        new(raw)
      end

      # Serializes state back to the Rails session
      def persist!(session)
        session[SESSION_KEY] = to_h
      end

      def to_h
        {
          current_catalog_id:    @current_catalog_id,
          current_portfolio_id:  @current_portfolio_id,
          current_exhibition_id: @current_exhibition_id,
          current_showing_id:    @current_showing_id,
          current_category_id:   @current_category_id,
          current_tag_id:        @current_tag_id
        }
      end

      # Safe record finder
      def current_catalog
        return nil unless @current_catalog_id
        Catalog.find_by(id: @current_catalog_id)
      end
      
      def current_category
        return nil unless @current_category_id
        Category.find_by(id: @current_category_id)
      end

      def current_tag
        return nil unless @current_tag_id
        Tag.find_by(id: @current_tag_id)
      end      
      def current_portfolio
        return nil unless @current_portfolio_id
        @current_portfolio ||= Portfolio.find_by(id: @current_portfolio_id)
      end

      def current_exhibition
        return nil unless @current_exhibition_id
        @current_exhibition ||= Exhibition.find_by(id: @current_exhibition_id)
      end

      def current_showing
        return nil unless @current_showing_id
        @current_showing ||= Showing.find_by(id: @current_showing_id)
      end

      # Atomically set active tag and synchronize its category
      def set_active_tag!(tag_or_id)
        tag = tag_or_id.is_a?(Tag) ? tag_or_id : Tag.find_by(id: tag_or_id)
        return unless tag

        @current_tag_id      = tag.id
        @current_category_id = tag.category_id
      end

      def clear!(session)
        session.delete(SESSION_KEY)
        @current_catalog_id = nil
        @current_category_id = nil
        @current_tag_id      = nil
        @current_portfolio_id  = nil
        @current_exhibition_id  = nil
        @current_showing_id  = nil
      end
    end  # class SessionState
    
# +++++++++++++++++++++++++++++++++++++++++++++++++
# --- Domain Taxonomy & Licensing Containers ---
# ******************************************************
    class CcLicense
      DICTIONARY = {
        all_rights_reserved: 0,
        cc_by:               1,
        cc_by_sa:            2,
        cc_by_nc:            3,
        cc_by_nc_sa:         4,
        cc_by_nd:            5,
        cc_by_nc_nd:         6,
        public_domain:       7
      }.freeze

      LABELS = {
        all_rights_reserved: "All Rights Reserved",
        cc_by:               "Creative Commons Attribution (CC BY 4.0)",
        cc_by_sa:            "Creative Commons Attribution-ShareAlike (CC BY-SA 4.0)",
        cc_by_nc:            "Creative Commons Attribution-NonCommercial (CC BY-NC 4.0)",
        cc_by_nc_sa:         "Creative Commons Attribution-NonCommercial-ShareAlike (CC BY-NC-SA 4.0)",
        cc_by_nd:            "Creative Commons Attribution-NoDerivatives (CC BY-ND 4.0)",
        cc_by_nc_nd:         "Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND 4.0)",
        public_domain:       "Public Domain / CC0"
      }.freeze

      URLS = {
        all_rights_reserved: nil,
        cc_by:               "https://creativecommons.org/licenses/by/4.0/",
        cc_by_sa:            "https://creativecommons.org/licenses/by-sa/4.0/",
        cc_by_nc:            "https://creativecommons.org/licenses/by-nc/4.0/",
        cc_by_nc_sa:         "https://creativecommons.org/licenses/by-nc-sa/4.0/",
        cc_by_nd:            "https://creativecommons.org/licenses/by-nd/4.0/",
        cc_by_nc_nd:         "https://creativecommons.org/licenses/by-nc-nd/4.0/",
        public_domain:       "https://creativecommons.org/publicdomain/zero/1.0/"
      }.freeze

      def self.label_for(key)
        LABELS[key.to_s.to_sym] || "Unknown License"
      end

      def self.url_for(key)
        URLS[key.to_s.to_sym]
      end

      def self.options_for_select
        DICTIONARY.keys.map { |k| [label_for(k), k.to_s] }
      end
    end # class CcLicense
# +++++++++++++++++++++++++++++++++++++++++++++++++

# +++++++++++++++++++++++++++++++++++++++++++++++++
    # --- Domain Enumeration Dictionaries ---
# +++++++++++++++++++++++++++++++++++++++++++++++++
    VENUE_TYPES = {
      commercial_gallery: 0,
      museum:             1,
      community_center:   2,
      public_space:       3,
      studio:             4,
      pop_up:             5
    }.freeze

    PORTFOLIO_STATUSES = {
      draft:    0,
      active:   1,
      archived: 2
    }.freeze

    EXHIBITION_STATUSES = {
      draft:     0,
      scheduled: 1,
      active:    2,
      completed: 3,
      archived:  4
    }.freeze

    SALES_POLICIES = {
      not_for_sale:     0,
      direct_inquiry:   1,
      venue_commission: 2,
      fixed_price:      3
    }.freeze

    SHOWING_STATUSES = {
      scheduled:   0,
      in_progress: 1,
      completed:   2,
      canceled:    3
    }.freeze

# +++++++++++++++++++++++++++++++++++++++++++++++++
#module constants
# +++++++++++++++++++++++++++++++++++++++++++++++++

  APP_NAME = "GALLERY"
  APP_NAME_HEAD = "#{APP_NAME}: "

# Application identity & attribution defaults
  DEFAULT_ARTIST_NAME   = "David S. Anderson".freeze
  DEFAULT_PREP_DAYS     = 1
  DEFAULT_TEARDOWN_DAYS = 1

  #  ------------------------------------------------------------
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

    # --- System & Security Utilities ---

    # returns a 22-char random string for sharing link
    def self.generate_token(bytes = 16)
      SecureRandom.urlsafe_base64(bytes)
    end
  #  ------------------------------------------------------------
end  # Class Environ
  
end  # module Gallery

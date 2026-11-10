# frozen_string_literal: true

# Gallery: 
# Copyright (c) 2026 David S Anderson, All Rights Reserved
#
# class SessionState -- maintains user state & navigation context across requests

module Gallery
  class Environ
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

        @current_catalog_id    = attrs[:current_catalog_id]
        @current_category_id   = attrs[:current_category_id]
        @current_tag_id        = attrs[:current_tag_id]
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

      # Safe record finders
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
        @current_catalog_id    = nil
        @current_category_id   = nil
        @current_tag_id        = nil
        @current_portfolio_id  = nil
        @current_exhibition_id = nil
        @current_showing_id    = nil
      end
    end  # CLASS
  end  # CLASS
end  # MODULE

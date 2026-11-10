# -----------------------------------------------------------------------------
# GALLERY: Curation Criteria Value Object
# File: lib/gallery/curation_criteria.rb
#
# PURPOSE:
# Encapsulates, sanitizes, and normalizes the multi-dimensional filter criteria
# used to discover, stage, and batch-curate photos into portfolios and exhibitions.
#
# Acting as a typed Value Object, this class decouples raw HTTP form/query parameters
# and serialized database recipes from downstream execution engines (PhotoQuery).
# It enforces strict type coercion, boundary checks, and canonical serialization
# across session state and the persisted `portfolios.curation_criteria` column.
#
# EXPECTED INVOCATION:
# Initialized from within environ.rb as a universal.
# 
# FILTERING CRITERIA DIMENSIONS:
# 1. Source Scope:
#    - Catalog, Portfolio, Exhibition
#    - Selection: None (entire library), single, or multiple source containers.
#
# 2. Taxonomy:
#    - Category / Tag
#    - Selection: None, single tag, or multiple tags.
#
# 3. Star Rating:
#    - Minimum threshold (>= N stars) or explicit rating match.
#    - Value range: -1 (reject diamond), 0 (unrated), 1..5 (progressive stars).
#
# 4. Date Window:
#    - Temporal capture bounds (start date, end date, or exact date match).
#
# 5. Talent:
#    - Model release / subject binding.
#    - Selection: None, single, or multiple Talent codes / IDs.
# -----------------------------------------------------------------------------

# frozen_string_literal: true


require 'date'
require 'json'

module Gallery
  class CurationCriteria
    attr_reader :catalog_ids,
                :portfolio_ids,
                :exhibition_ids,
                :tag_ids,
                :talent_ids,
                :min_stars,
                :exact_stars,
                :start_date,
                :end_date

    def initialize(attrs = {})
      attrs = normalize_input(attrs)

      sources = attrs[:sources] || {}
      @catalog_ids    = sanitize_ids(sources[:catalog_ids] || attrs[:catalog_ids])
      @portfolio_ids  = sanitize_ids(sources[:portfolio_ids] || attrs[:portfolio_ids])
      @exhibition_ids = sanitize_ids(sources[:exhibition_ids] || attrs[:exhibition_ids])

      @tag_ids        = sanitize_ids(attrs[:tag_ids])
      @talent_ids     = sanitize_ids(attrs[:talent_ids])

      @min_stars      = parse_stars(attrs[:min_stars])
      @exact_stars    = parse_stars(attrs[:exact_stars])

      date_range      = attrs[:date_range] || {}
      @start_date     = parse_date(date_range[:start_date] || attrs[:start_date])
      @end_date       = parse_date(date_range[:end_date] || attrs[:end_date])
    end

    def empty?
      !active?
    end

    def active?
      @catalog_ids.any? ||
        @portfolio_ids.any? ||
        @exhibition_ids.any? ||
        @tag_ids.any? ||
        @talent_ids.any? ||
        !@min_stars.nil? ||
        !@exact_stars.nil? ||
        !@start_date.nil? ||
        !@end_date.nil?
    end

    def to_h
      {
        sources: {
          catalog_ids:    @catalog_ids,
          portfolio_ids:  @portfolio_ids,
          exhibition_ids: @exhibition_ids
        },
        tag_ids:     @tag_ids,
        talent_ids:  @talent_ids,
        min_stars:   @min_stars,
        exact_stars: @exact_stars,
        date_range: {
          start_date: @start_date&.iso8601,
          end_date:   @end_date&.iso8601
        }
      }
    end

    def to_json(*args)
      to_h.to_json(*args)
    end

    # Serializer interface for ActiveRecord serialize :curation_criteria, coder: Gallery::CurationCriteria
    def self.dump(obj)
      return nil if obj.nil?

      criteria = obj.is_a?(CurationCriteria) ? obj : new(obj)
      criteria.to_json
    end

    def self.load(raw)
      return new({}) if raw.blank?

      parsed = raw.is_a?(String) ? JSON.parse(raw) : raw
      new(parsed)
    rescue JSON::ParserError
      new({})
    end

    private

    def normalize_input(input)
      h = case input
          when String
            begin
              JSON.parse(input)
            rescue JSON::ParserError
              {}
            end
          when ActionController::Parameters
            input.to_unsafe_h
          else
            input.respond_to?(:to_h) ? input.to_h : {}
          end

      h.respond_to?(:deep_symbolize_keys) ? h.deep_symbolize_keys : deep_symbolize(h)
    end

    def deep_symbolize(obj)
      case obj
      when Hash
        obj.each_with_object({}) { |(k, v), res| res[k.to_sym] = deep_symbolize(v) }
      when Array
        obj.map { |elem| deep_symbolize(elem) }
      else
        obj
      end
    end

    def sanitize_ids(values)
      Array(values).flatten.reject(&:blank?).map(&:to_i).uniq.sort
    end

    def parse_stars(val)
      return nil if val.blank?

      i = val.to_i
      (-1..5).cover?(i) ? i : nil
    end

    def parse_date(val)
      return val if val.is_a?(Date)
      return val.to_date if val.respond_to?(:to_date)
      return nil if val.blank?

      Date.iso8601(val.to_s.strip)
    rescue ArgumentError
      begin
        Date.parse(val.to_s.strip)
      rescue ArgumentError
        nil
      end
    end
  end
end

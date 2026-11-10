# frozen_string_literal: true

# -----------------------------------------------------------------------------
# GALLERY: Photo Query Object
# File: app/models/photo_query.rb
#
# PURPOSE:
# Composable ActiveRecord query builder that executes candidate photo discovery
# driven by a ::Gallery::CurationCriteria value object.
#
# GUARDRAILS:
# 1. Empty criteria resolves to Photo.none (WHERE 1=0) to prevent unconstrained
#    scans across the entire photo archive.
# 2. Provides count and capacity validation against ::Gallery::Environ limits.
# -----------------------------------------------------------------------------

class PhotoQuery
  class CapacityExceededError < StandardError; end

  attr_reader :criteria, :relation, :limit

  def initialize(criteria = {}, base_relation = Photo.all, limit: ::Gallery::Environ::MAX_PORTFOLIO_SIZE, **kwargs)
    raw_criteria = criteria.is_a?(Hash) && criteria.empty? && kwargs.any? ? kwargs : criteria
    @criteria    = raw_criteria.is_a?(::Gallery::CurationCriteria) ? raw_criteria : ::Gallery::CurationCriteria.new(raw_criteria)
    @relation    = base_relation
    @limit       = limit
  end

  # Resolves the scoped ActiveRecord relation.
  # Returns Photo.none if no filtering criteria are active.
  def resolve
    return Photo.none if @criteria.empty?

    scope = @relation
    scope = apply_sources(scope)
    scope = apply_tags(scope)
    scope = apply_stars(scope)
    scope = apply_date_range(scope)
    scope = apply_talent(scope)

    scope.distinct
  end

  # Evaluates the number of matched candidate photos
  def count
    resolve.count
  end

  # Capacity check predicate
  def exceeds_capacity?(max = @limit)
    return false if @criteria.empty?

    count > max
  end

  # Safety execution: returns relation or raises CapacityExceededError
  def resolve_safe!(max = @limit)
    current_count = count
    if current_count > max
      raise CapacityExceededError, "Query matched #{current_count} photos, exceeding capacity limit of #{max}."
    end

    resolve
  end

  private

  def apply_sources(scope)
    source_relations = []

    if @criteria.catalog_ids.any?
      source_relations << scope.where(catalog_id: @criteria.catalog_ids)
    end

    if @criteria.portfolio_ids.any?
      portfolio_photo_ids = PortfolioItem.where(portfolio_id: @criteria.portfolio_ids).select(:photo_id)
      source_relations << scope.where(id: portfolio_photo_ids)
    end

    if @criteria.exhibition_ids.any?
      exhibition_photo_ids = ExhibitionItem.where(exhibition_id: @criteria.exhibition_ids).select(:photo_id)
      source_relations << scope.where(id: exhibition_photo_ids)
    end

    return scope if source_relations.empty?

    # Combine with SQL OR
    source_relations.reduce(:or)
  end

  def apply_tags(scope)
    return scope if @criteria.tag_ids.empty?

    scope.joins(:tags).where(tags: { id: @criteria.tag_ids })
  end

  def apply_stars(scope)
    if @criteria.exact_stars.present?
      scope = scope.where(stars: @criteria.exact_stars)
    elsif @criteria.min_stars.present?
      scope = scope.where("photos.stars >= ?", @criteria.min_stars)
    end
    scope
  end

  def apply_date_range(scope)
    if @criteria.start_date.present?
      scope = scope.where("photos.photodate >= ?", @criteria.start_date.beginning_of_day)
    end

    if @criteria.end_date.present?
      scope = scope.where("photos.photodate <= ?", @criteria.end_date.end_of_day)
    end

    scope
  end

  def apply_talent(scope)
    return scope if @criteria.talent_ids.empty?

    catalog_subquery = Catalog.where(talent_id: @criteria.talent_ids).select(:id)
    scope.where(catalog_id: catalog_subquery)
  end
end

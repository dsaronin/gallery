# frozen_string_literal: true

# -----------------------------------------------------------------------------
# GALLERY: GangTaggable Concern
# File: app/models/concerns/gang_taggable.rb
#
# PURPOSE:
# Provides idempotent bulk (union OR) assignment of a Category::Tag across all
# member Photo records in a collection (Catalog, Portfolio, or Exhibition).
# -----------------------------------------------------------------------------

module GangTaggable
  extend ActiveSupport::Concern

  GangTagResult = Data.define(:tag, :total_count, :added_count, :skipped_count)

  # Assigns `tag` to every distinct photo in the collection that does not yet
  # carry it. Safe and idempotent if some or all items already have `tag`.
  def gang_assign_tag!(tag)
    raise ArgumentError, "Expected a Tag instance" unless tag.is_a?(Tag)

    target_ids = photos.distinct.pluck(:id)
    return GangTagResult.new(tag: tag, total_count: 0, added_count: 0, skipped_count: 0) if target_ids.empty?

    existing_ids = tag.photos.where(id: target_ids).pluck(:id)
    missing_ids  = target_ids - existing_ids

    assign_missing_photos!(tag, missing_ids) if missing_ids.any?

    GangTagResult.new(
      tag:           tag,
      total_count:   target_ids.size,
      added_count:   missing_ids.size,
      skipped_count: existing_ids.size
    )
  end
# ***************************************

  private

# ***************************************
  def assign_missing_photos!(tag, missing_ids)
    ActiveRecord::Base.transaction do
      tag.photos << Photo.where(id: missing_ids)
    end
  end

# ***************************************
  
end  # module

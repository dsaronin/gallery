# frozen_string_literal: true

# -----------------------------------------------------------------------------
# GALLERY: Curatable Concern
# File: app/models/concerns/curatable.rb
#
# PURPOSE:
# Unifies candidate photo resolution, curation recipe persistence, and batch
# insertion across Portfolio and Exhibition models.
# -----------------------------------------------------------------------------

module Curatable
  extend ActiveSupport::Concern

  included do
    serialize :curation_criteria, coder: Gallery::CurationCriteria
  end

  # If candidate_photos is kept for backwards compatibility:
  def candidate_photos
    last_criteria = curation_criteria.is_a?(Array) ? curation_criteria.last : curation_criteria
    return Photo.none if last_criteria.blank?

    PhotoQuery.new(last_criteria, limit: max_curation_size).resolve
  end

  # Batch creates join records for matching photos not already present in the target
  def curate_photos!(criteria, limit: max_curation_size)
    criteria_obj = criteria.is_a?(Gallery::CurationCriteria) ? criteria : Gallery::CurationCriteria.new(criteria)

    query = PhotoQuery.new(criteria_obj, limit: limit)
    matches = query.resolve_safe!(limit)

    existing_ids = items_association.pluck(:photo_id)
    new_ids = matches.pluck(:id) - existing_ids

    # Append criteria to the audit history
    history = Array.wrap(curation_criteria).compact
    history << criteria_obj
    self.curation_criteria = history
    save!

    return 0 if new_ids.empty?

    current_max_pos = items_association.maximum(:position) || 0
    now = Time.current
    foreign_key_col = "#{self.class.model_name.singular}_id"

    records = new_ids.map.with_index(1) do |pid, idx|
      {
        foreign_key_col => id,
        photo_id: pid,
        position: current_max_pos + idx,
        likes_count: 0,
        created_at: now,
        updated_at: now
      }
    end

    items_association.klass.insert_all(records)
    new_ids.size
  end

  # Interface contract to be fulfilled by including models:
  def max_curation_size
    raise NotImplementedError, "#{self.class} must implement #max_curation_size"
  end

  def items_association
    raise NotImplementedError, "#{self.class} must implement #items_association"
  end
end  #class

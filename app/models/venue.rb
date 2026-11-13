# frozen_string_literal: true

class Venue < ApplicationRecord
  enum :venue_type, ::Gallery::Environ::VENUE_TYPES, default: :commercial_gallery
  enum :status,     ::Gallery::Environ::VENUE_STATUSES, default: :pending

  has_many :exhibitions, dependent: :restrict_with_error
  has_many :showings, dependent: :restrict_with_error

  validates :name, presence: true
  validates :wall_linear_meters, numericality: { greater_than: 0 }, allow_nil: true
  validates :rate_per_day, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_destroy :ensure_deletable_status, prepend: true

  def deletable?
    (mock? || pending?) && exhibitions.none? && showings.none?
  end

  def self.dashboard_metrics
    {
      venues_count: count,
      total_wall_meters: sum(:wall_linear_meters) || 0,
      talents_count: (Talent.count rescue 0),
      categories_count: (Category.count rescue 0),
      tags_count: (Tag.count rescue 0)
    }
  end

  private

  def ensure_deletable_status
    return if mock? || pending?

    errors.add(:base, "Cannot delete venue while status is #{status.humanize}.")
    throw(:abort)
  end
end

# frozen_string_literal: true

class Showing < ApplicationRecord
  include DateRangeValidatable
  validates_date_range start_attr: :start_date, end_attr: :end_date

  enum :status, ::Gallery::Environ::SHOWING_STATUSES, default: :scheduled

  belongs_to :exhibition, optional: true
  belongs_to :venue, optional: true

  validates :title, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :prep_days, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :teardown_days, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :rental_cost, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :visitation_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_destroy :ensure_deletable, prepend: true

  def deletable?
    exhibition_id.nil? && Exhibition.where(showing_id: id).none?
  end

  def self.dashboard_metrics
    next_showing = where("start_date >= ?", Date.current).order(:start_date).first rescue nil

    {
      next_date: next_showing ? next_showing.start_date.strftime("%b %d, %Y") : "None",
      days_remaining: next_showing ? (next_showing.start_date.to_date - Date.current).to_i : 0,
      next_venue: next_showing&.venue ? next_showing.venue.name : "None",
      booked_count: (where("start_date >= ?", Date.current).count rescue 0)
    }
  end

  private

  def ensure_deletable
    if destroyed_by_association&.active_record == Exhibition
      Exhibition.where(showing_id: id).update_all(showing_id: nil)
      return
    end

    return if deletable?

    errors.add(:base, "Cannot delete showing while associated with an exhibition.")
    throw(:abort)
  end

end   # class


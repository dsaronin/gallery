class Showing < ApplicationRecord
  include DateRangeValidatable
  validates_date_range start_attr: :start_date, end_attr: :end_date

  enum :status, ::Gallery::Environ::SHOWING_STATUSES, default: :scheduled

  belongs_to :exhibition
  belongs_to :venue

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :prep_days, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :teardown_days, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :rental_cost, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :visitation_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.dashboard_metrics
    next_showing = where("start_date >= ?", Date.current).order(:start_date).first rescue nil

    {
      next_date: next_showing ? next_showing.start_date.strftime("%b %d, %Y") : "None",
      days_remaining: next_showing ? (next_showing.start_date.to_date - Date.current).to_i : 0,
      next_venue: next_showing&.venue ? next_showing.venue.name : "None",
      booked_count: ( where("start_date >= ?", Date.current).count rescue 0 )
    }
  end

end

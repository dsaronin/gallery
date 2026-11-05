class Portfolio < ApplicationRecord
  enum :status, Gallery::Environ::PORTFOLIO_STATUSES, default: :draft

  belongs_to :placard, optional: true
  has_many :portfolio_items, -> { order(:position) }, dependent: :destroy, inverse_of: :portfolio
  has_many :photos, through: :portfolio_items
  has_many :exhibitions, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :title, presence: true
  validates :likes_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :share_token, uniqueness: true, allow_nil: true

  before_validation :assign_share_token, on: :create

  def self.dashboard_metrics
    {
      total_count: count,
      active_count: ( where(active: true).count rescue 0 ),
      draft_count:  ( where(active: false).count rescue 0 ),
      curated_photos_count: ( joins(:portfolio_items).count rescue 0 )
    }
  end

  private

  def assign_share_token
    self.share_token ||= Gallery::Environ.generate_token(16)
  end
end

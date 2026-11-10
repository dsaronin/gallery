class Portfolio < ApplicationRecord
  include Curatable

  enum :status, ::Gallery::Environ::PORTFOLIO_STATUSES, default: :draft

  belongs_to :placard, optional: true
  has_many :portfolio_items, -> { order(:position) }, dependent: :destroy, inverse_of: :portfolio
  has_many :photos, through: :portfolio_items
  has_many :exhibitions, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :title, presence: true
  validates :likes_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :share_token, uniqueness: true, allow_nil: true

  before_validation :assign_share_token, on: :create

# **********************************************************
  def self.dashboard_metrics
    {
      total_count: count,
      active_count: where(status: statuses[:active]).count,
      draft_count:  where(status: statuses[:draft]).count,
      curated_photos_count: joins(:portfolio_items).count
    }
  end
# **********************************************************

  def max_curation_size
    ::Gallery::Environ::MAX_PORTFOLIO_SIZE
  end

  def items_association
    portfolio_items
  end

# **********************************************************
  private

  def assign_share_token
    self.share_token ||= ::Gallery::Environ.generate_token(16)
  end
end

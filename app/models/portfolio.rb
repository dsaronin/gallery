class Portfolio < ApplicationRecord
  include Curatable

  enum :status, Gallery::Environ::PORTFOLIO_STATUSES, default: :draft

  belongs_to :placard, optional: true
  has_many :portfolio_items, -> { order(:position) }, dependent: :destroy, inverse_of: :portfolio
  has_many :photos, through: :portfolio_items
  has_many :exhibitions, dependent: :restrict_with_error

  serialize :curation_criteria, coder: Gallery::CurationCriteria

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
  # Returns an ActiveRecord::Relation of photos matching the saved curation criteria
  def candidate_photos
    PhotoQuery.new(curation_criteria).resolve
  end

  # Batch creates PortfolioItem records for matching photos not already in this portfolio
  def curate_photos!(limit: Gallery::Environ::MAX_PORTFOLIO_SIZE)
    query = PhotoQuery.new(curation_criteria, limit: limit)
    matches = query.resolve_safe!(limit)

    existing_photo_ids = portfolio_items.pluck(:photo_id)
    new_photo_ids = matches.pluck(:id) - existing_photo_ids

    return 0 if new_photo_ids.empty?

    current_max_pos = portfolio_items.maximum(:position) || 0
    now = Time.current

    items_to_insert = new_photo_ids.map.with_index(1) do |pid, idx|
      {
        portfolio_id: id,
        photo_id: pid,
        position: current_max_pos + idx,
        created_at: now,
        updated_at: now
      }
    end

    PortfolioItem.insert_all(items_to_insert)
    new_photo_ids.size
  end

  def max_curation_size
    Gallery::Environ::MAX_PORTFOLIO_SIZE
  end

  def items_association
    portfolio_items
  end

# **********************************************************
  private

  def assign_share_token
    self.share_token ||= Gallery::Environ.generate_token(16)
  end
end

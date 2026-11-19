class Portfolio < ApplicationRecord
  include Curatable
  include Placardable
  include GangTaggable

# **********************************************************
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

  # Class-level fallback PlacardData factory when no persisted Placard exists
  def self.default_placard_data(portfolio, preceding_data = nil)
    base = preceding_data || ::Gallery::Environ::PlacardData.new
    title_seed = base.merge(
      Placard,
      { title: portfolio.title.presence || portfolio.name },
      status: :default,
      provenance_source: portfolio
    )
    attrs = {
      artist_name:      ::Gallery::Environ::DEFAULT_ARTIST_NAME,
      copyright_holder: ::Gallery::Environ::DEFAULT_ARTIST_NAME,
      copyright_year:   Date.current.year,
      cc_license:       ::Gallery::Environ::CcLicense::DICTIONARY[:all_rights_reserved]
    }
    title_seed.merge(portfolio, attrs, status: :default)
  end

  # Resolves COLLECTION partition cascade: default fallback -> persisted Portfolio#placard
  def placard_data(preceding_data = nil)
    base = self.class.default_placard_data(self, preceding_data)
    placard ? placard.placard_data(base, provenance_source: self) : base
  end

# **********************************************************

# **********************************************************
  private

  def assign_share_token
    self.share_token ||= ::Gallery::Environ.generate_token(16)
  end
end

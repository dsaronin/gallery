class Exhibition < ApplicationRecord
  include Curatable
  include Placardable
  include GangTaggable

# *******************************************************
  enum :status, ::Gallery::Environ::EXHIBITION_STATUSES, default: :draft
  enum :sales_policy, ::Gallery::Environ::SALES_POLICIES, default: :not_for_sale

  belongs_to :portfolio, optional: true
  belongs_to :venue, optional: true
  belongs_to :placard, optional: true
  belongs_to :talent, optional: true
  belongs_to :showing, optional: true, class_name: "Showing", foreign_key: :showing_id

  has_many :exhibition_items, -> { order(:position) }, dependent: :destroy, inverse_of: :exhibition
  has_many :photos, through: :exhibition_items
  has_many :showings, dependent: :destroy

  validates :title, presence: true
  validates :budget, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :total_expenses, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

# *******************************************************
  def self.dashboard_metrics
    {
      total_count: count,
      draft_count: where(status: statuses[:draft]).count,
      scheduled_count: where(status: statuses[:scheduled]).count,
      active_count: where(status: statuses[:active]).count,
      completed_count: where(status: statuses[:completed]).count,
      curated_photos_count: joins(:exhibition_items).count
    }
  end
# *******************************************************

  def max_curation_size
    ::Gallery::Environ::MAX_EXHIBITION_SIZE
  end

# *******************************************************
  def items_association
    exhibition_items
  end
# *******************************************************

  # Class-level fallback PlacardData factory when no persisted Placard exists
  def self.default_placard_data(exhibition, preceding_data = nil)
    base = preceding_data || ::Gallery::Environ::PlacardData.new
    item_seed_attrs = {
      title:   exhibition.title,
      subject: exhibition.talent&.talent_name.presence
    }.compact

    title_seed = base.merge(Placard, item_seed_attrs, status: :default, provenance_source: exhibition)
    attrs = {
      artist_name:      ::Gallery::Environ::DEFAULT_ARTIST_NAME,
      copyright_holder: ::Gallery::Environ::DEFAULT_ARTIST_NAME,
      copyright_year:   Date.current.year,
      cc_license:       ::Gallery::Environ::CcLicense::DICTIONARY[:all_rights_reserved]
    }
    title_seed.merge(exhibition, attrs, status: :default)
  end

  # Resolves COLLECTION partition cascade:
  # Portfolio.placard -> Exhibition fallback -> persisted Exhibition#placard
  def placard_data(preceding_data = nil)
    upstream = if portfolio
                 port_pd = portfolio.placard_data(preceding_data)
                 item_seed_attrs = {
                   title:   title,
                   subject: talent&.talent_name.presence
                 }.compact
                 port_pd.merge(Placard, item_seed_attrs, status: :default, provenance_source: self)
               else
                 self.class.default_placard_data(self, preceding_data)
               end

    placard ? placard.placard_data(upstream, provenance_source: self) : upstream
  end
# *******************************************************

end  #class

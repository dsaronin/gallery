class Exhibition < ApplicationRecord
  include Curatable

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

  def items_association
    exhibition_items
  end
# *******************************************************

end  #class

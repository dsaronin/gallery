class Exhibition < ApplicationRecord
  enum :status, Gallery::Environ::EXHIBITION_STATUSES, default: :draft
  enum :sales_policy, Gallery::Environ::SALES_POLICIES, default: :not_for_sale

  belongs_to :portfolio
  belongs_to :venue
  belongs_to :placard, optional: true
  belongs_to :talent, optional: true
  belongs_to :showing, optional: true, class_name: "Showing", foreign_key: :showing_id

  has_many :exhibition_items, -> { order(:position) }, dependent: :destroy, inverse_of: :exhibition
  has_many :portfolio_items, through: :exhibition_items
  has_many :showings, dependent: :destroy

  validates :title, presence: true
  validates :budget, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :total_expenses, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  def self.dashboard_metrics
    {
      staged_count: ( where(status: :staged).count rescue 0 ),
      planning_count: ( where(status: :planning).count rescue 0 ),
      active_count: ( where(status: :active).count rescue 0 )
    }
  end


end  #class

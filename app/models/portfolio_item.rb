class PortfolioItem < ApplicationRecord
  include Positionable
  include Placardable

  acts_as_positionable scope: :portfolio_id

  belongs_to :portfolio
  belongs_to :photo
  belongs_to :placard, optional: true

  validates :photo_id, uniqueness: { scope: :portfolio_id, message: "is already included in this portfolio" }
  validates :likes_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Resolves dual-track cascade:
  # COLLECTION track (Portfolio) + ITEM track (Photo -> PortfolioItem#placard)
  def placard_data(preceding_data = nil)
    col_pd  = portfolio ? portfolio.placard_data(preceding_data) : (preceding_data || ::Gallery::Environ::PlacardData.new)
    item_pd = photo ? photo.placard_data(col_pd) : col_pd
    placard ? placard.placard_data(item_pd, provenance_source: self) : item_pd
  end

end  # class

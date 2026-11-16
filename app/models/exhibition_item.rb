class ExhibitionItem < ApplicationRecord
  include Positionable
  include Placardable
  acts_as_positionable scope: :exhibition_id

  belongs_to :exhibition
  belongs_to :photo
  belongs_to :placard, optional: true

  validates :photo_id, uniqueness: { scope: :exhibition_id, message: "is already included in this exhibition" }
  validates :likes_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

# *****************************************************************
  # Resolves dual-track cascade:
  # COLLECTION track (Portfolio -> Exhibition) +
  # ITEM track (Photo -> PortfolioItem#placard -> ExhibitionItem#placard)
# *****************************************************************
  def placard_data(preceding_data = nil)
    col_pd  = exhibition ? exhibition.placard_data(preceding_data) : (preceding_data || ::Gallery::Environ::PlacardData.new)
    item_pd = photo ? photo.placard_data(col_pd) : col_pd

    # Cascade ITEM_FIELDS from matching PortfolioItem's persisted Placard if present
    source_pi = matching_portfolio_item
    if source_pi&.placard
      pi_item_attrs = source_pi.placard.placard_attributes.slice(*::Gallery::Environ::PlacardData::ITEM_FIELDS)
      item_pd = item_pd.merge(source_pi, pi_item_attrs, status: :cascaded) if pi_item_attrs.any?
    end

    placard ? placard.placard_data(item_pd, provenance_source: self) : item_pd
  end
# *****************************************************************

  private

# *****************************************************************
  def matching_portfolio_item
    return nil unless photo_id

    if exhibition&.portfolio_id
      PortfolioItem.find_by(portfolio_id: exhibition.portfolio_id, photo_id: photo_id)
    else
      PortfolioItem.find_by(photo_id: photo_id)
    end
  end
# *****************************************************************

end  # class

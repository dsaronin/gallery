class PortfolioItem < ApplicationRecord
  include Positionable
  acts_as_positionable scope: :portfolio_id

  belongs_to :portfolio
  belongs_to :photo
  belongs_to :placard, optional: true

  validates :photo_id, uniqueness: { scope: :portfolio_id, message: "is already included in this portfolio" }
  validates :likes_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end

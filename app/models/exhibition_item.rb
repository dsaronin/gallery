class ExhibitionItem < ApplicationRecord
  include Positionable
  acts_as_positionable scope: :exhibition_id

  belongs_to :exhibition
  belongs_to :photo
  belongs_to :placard, optional: true

  validates :photo_id, uniqueness: { scope: :exhibition_id, message: "is already included in this exhibition" }
  validates :likes_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end

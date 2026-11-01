class Tag < ApplicationRecord
  belongs_to :category
  has_and_belongs_to_many :photos

  validates :name, presence: true,
                   uniqueness: { scope: :category_id, case_sensitive: false }

  scope :themes, -> { where(theme: true) }
  scope :keywords, -> { where(theme: false) }
  scope :alphabetical, -> { order(:name) }

  default_scope { order(:name) }
end

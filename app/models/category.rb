class Category < ApplicationRecord
  has_many :tags, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  default_scope { order(:name) }
end

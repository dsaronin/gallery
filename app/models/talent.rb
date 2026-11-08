class Talent < ApplicationRecord
# -----------------------------
  has_many :catalogs, dependent: :nullify
  has_many :photos, through: :catalogs
  belongs_to :cover, class_name: "Photo", optional: true

  validates :talent_code, presence: true, uniqueness: true
  validates :talent_name, presence: true
  validates :first_name,  presence: true
# -----------------------------
end


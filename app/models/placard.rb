class Placard < ApplicationRecord
  enum :cc_license, Gallery::Environ::CcLicense::DICTIONARY, default: :all_rights_reserved

  has_many :portfolios, dependent: :nullify
  has_many :portfolio_items, dependent: :nullify
  has_many :exhibitions, dependent: :nullify
  has_many :exhibition_items, dependent: :nullify

  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :copyright_year, numericality: { only_integer: true, greater_than: 1900 }, allow_nil: true

end # class


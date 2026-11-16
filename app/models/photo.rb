# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2023 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

class Photo < ApplicationRecord
  include Placardable

  belongs_to :catalog
  has_one :talent, through: :catalog
  
  has_and_belongs_to_many :tags
  has_many :portfolio_items, dependent: :destroy
  has_many :portfolios, through: :portfolio_items
  has_many :exhibition_items, dependent: :destroy
  has_many :exhibitions, through: :exhibition_items
 
  validates :latitude, numericality: {allow_nil: true}
  validates :longitude, numericality: {allow_nil: true}
  validates :stars, numericality: { only_integer: true, in: -1..5 }
  validates_presence_of  :photo_dsc
  validates_presence_of  :filename
  validates_presence_of  :photodate

# ------------------------------------------------------------------------------
#      t.string :photo_dsc
#      t.string :filename
#      t.integer :stars
#      t.datetime :photodate
#      t.float :latitude
#      t.float :longitude
#      t.integer  :width
#      t.integer  :height
#      t.string :notes
#      t.references :catalog, null: false, foreign_key: true
#      t.references :talent, null: true, foreign_key: true
#      t.references :portfolio, null: true, foreign_key: true
# ------------------------------------------------------------------------------
# Scopes
  scope :active_candidates, -> { where("stars >= 0") }
  scope :showable,          -> { where("stars >= 3") }
  scope :rejected,          -> { where(stars: -1) }
  scope :unrated,           -> { where(stars: 0) }
  scope :rated,             -> { where("stars >= 1") }
  scope :by_stars,          ->(val) { where(stars: val) }

  # Predicates & Helper Methods
  def rejected?
    stars == -1
  end

  def unrated?
    stars == 0
  end

  def rated?
    stars.positive?
  end

  def rated?
    stars.positive?
  end

  # Placardable baseline ITEM_FIELDS derived from intrinsic Photo metadata
  def placard_attributes
    {
      title:                photo_dsc.presence || File.basename(filename.to_s, ".*").presence,
      subject:              talent&.talent_name.presence,
      date_created_display: photodate&.year&.to_s,
      location_display:     formatted_coordinates,
      curatorial_notes:     notes.presence
    }.compact
  end

  def placard_provenance_status
    :intrinsic
  end

  private

  def formatted_coordinates
    return nil unless latitude.present? && longitude.present?

    format("%.4f, %.4f", latitude, longitude)
  end


# ------------------------------------------------------------------------------
end   # class  Photo

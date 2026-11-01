# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2023 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

class Photo < ApplicationRecord

  belongs_to :folder
  belongs_to :talent, optional: true
  
  has_and_belongs_to_many :tags
  has_and_belongs_to_many  :portfolio_items
 
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
#      t.references :folder, null: false, foreign_key: true
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



# ------------------------------------------------------------------------------
end   # class  Photo

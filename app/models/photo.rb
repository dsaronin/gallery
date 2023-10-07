# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2023 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

class Photo < ApplicationRecord

  belongs_to :folder
  belongs_to :portfolio, optional: true
  belongs_to :talent, optional: true
 
  validates :latitude, numericality: true
  validates :longitude, numericality: true
  validates :rating, numericality: { only_integer: true, in: (0..5), allow_nil: true }
  validates_presence_of  :photo_dsc
  validates_presence_of  :filename
  validates_presence_of  :photodate

# ------------------------------------------------------------------------------
#      t.string :photo_dsc
#      t.string :filename
#      t.integer :rating
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




# ------------------------------------------------------------------------------
end   # class  Photo

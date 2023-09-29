class Photo < ApplicationRecord
  belongs_to :folder
  belongs_to :portfolio, optional: true
  belongs_to :talent, optional: true

#      t.string :photo_dsc
#      t.string :filename
#      t.integer :rating
#      t.datetime :photodate
#      t.float :latitude
#      t.float :longitude
#      t.string :notes
#      t.references :folder, null: false, foreign_key: true
#      t.references :talent, null: true, foreign_key: true
#      t.references :portfolio, null: true, foreign_key: true




end   # class  Photo

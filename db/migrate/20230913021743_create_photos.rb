class CreatePhotos < ActiveRecord::Migration[7.0]
  def change
    create_table :photos do |t|
      t.string :photo_dsc
      t.string :filename
      t.integer :rating
      t.datetime :photodate
      t.float :latitude
      t.float :longitude
      t.string :notes
      t.references :talent, null: true, foreign_key: true
      t.references :photoshoot, null: true, foreign_key: true

      t.timestamps
    end
  end
end

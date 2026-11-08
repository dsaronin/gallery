class CreatePhotos < ActiveRecord::Migration[7.0]
  def change
    create_table :photos do |t|
      t.string :photo_dsc
      t.string :filename
      t.integer :stars, default: 0, null: false
      t.datetime :photodate
      t.integer  :width
      t.integer  :height
      t.float :latitude
      t.float :longitude
      t.string :notes
      t.references :catalog, null: false, foreign_key: true

      t.timestamps
    end

    # Establish the delayed foreign key for talent cover photo
    add_foreign_key :talent, :photos, column: :cover_id
  end
end

class CreatePlacards < ActiveRecord::Migration[7.1]
  def change
    create_table :placards do |t|
      t.string  :title
      t.string  :subtitle
      t.text    :curatorial_notes
      t.string  :artist_name
      t.string  :date_created_display
      t.string  :location_display
      t.string  :medium
      t.string  :dimensions_display
      t.string  :edition_info
      t.integer :price
      t.string  :sales_notes
      t.integer :cc_license, null: false, default: 0
      t.integer :copyright_year
      t.string  :copyright_holder

      t.timestamps
    end
  end
end

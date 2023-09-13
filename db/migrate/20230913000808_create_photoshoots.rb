class CreatePhotoshoots < ActiveRecord::Migration[7.0]
  def change
    create_table :photoshoots do |t|
      t.string :shoot_name
      t.string :shoot_title
      t.date :shoot_date
      t.string :shoot_location
      t.string :theme
      t.string :notes
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end

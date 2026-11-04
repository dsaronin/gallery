class CreateVenues < ActiveRecord::Migration[7.1]
  def change
    create_table :venues do |t|
      t.string  :name, null: false
      t.integer :venue_type, null: false, default: 0
      t.string  :space_name
      t.integer :wall_linear_meters
      t.integer :rate_per_day
      t.string  :address
      t.string  :contact_name
      t.string  :contact_position
      t.string  :contact_email
      t.string  :contact_phone
      t.string  :website_url
      t.text    :notes

      t.timestamps
    end
  end
end

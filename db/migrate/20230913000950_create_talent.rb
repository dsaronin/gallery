class CreateTalent < ActiveRecord::Migration[7.0]
  def change
    create_table :talent do |t|
      t.string  :talent_code
      t.string  :talent_name
      t.string  :last_name
      t.string  :first_name
      t.date    :talent_dob
      t.string  :talent_address
      t.string  :talent_email
      t.string  :talent_phone
      t.date    :talent_release
      t.integer :cover_id

      t.timestamps
    end
    add_index :talent, :talent_code, unique: true
    add_index :talent, :cover_id
  end
end

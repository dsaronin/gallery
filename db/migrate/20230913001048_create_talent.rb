class CreateTalent < ActiveRecord::Migration[7.0]
  def change
    create_table :talent do |t|
      t.string :talent_code
      t.string :talent_nbr
      t.string :talent_name
      t.string :first_name
      t.string :last_name
      t.date :talent_dob
      t.date :talent_release

      t.timestamps
    end
    add_index :talent, :talent_code, unique: true
  end
end

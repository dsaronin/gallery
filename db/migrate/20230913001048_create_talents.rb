class CreateTalents < ActiveRecord::Migration[7.0]
  def change
    create_table :talents do |t|
      t.string :model_code
      t.string :model_name
      t.string :first_name
      t.string :last_name
      t.string :gender
      t.integer :shoot_age
      t.date :model_release
      t.string :model_nbr

      t.timestamps
    end
    add_index :talents, :model_code, unique: true
  end
end

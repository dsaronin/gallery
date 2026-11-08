class CreateCatalogs < ActiveRecord::Migration[7.0]
  def change
    create_table :catalogs do |t|
      t.string :name
      t.string :fname
      t.string :fpath
      t.references :talent, foreign_key: { to_table: :talent }, null: true

      t.timestamps
    end
    add_index :catalogs, :fname, unique: true
  end
end

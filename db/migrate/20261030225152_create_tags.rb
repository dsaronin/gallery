class CreateTags < ActiveRecord::Migration[7.1]
  def change
    create_table :tags do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :theme, default: false, null: false

      t.timestamps
    end

    add_index :tags, [:category_id, :name], unique: true
    add_index :tags, :theme
  end
end

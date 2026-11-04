class CreateExhibitionItems < ActiveRecord::Migration[7.1]
  def change
    create_table :exhibition_items do |t|
      t.integer    :position, null: false
      t.integer    :likes_count, null: false, default: 0
      t.references :placard, foreign_key: true, index: true
      t.references :exhibition, null: false, foreign_key: true, index: true
      t.references :portfolio_item, null: false, foreign_key: true, index: true

      t.timestamps
    end

    add_index :exhibition_items, [:exhibition_id, :position], unique: true
    add_index :exhibition_items, [:exhibition_id, :portfolio_item_id], unique: true
  end
end

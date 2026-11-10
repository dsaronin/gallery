class CreatePortfolios < ActiveRecord::Migration[7.1]
  def change
    create_table :portfolios do |t|
      t.string     :name, null: false
      t.string     :title, null: false
      t.integer    :status, null: false, default: 0
      t.integer    :likes_count, null: false, default: 0
      t.references :placard, foreign_key: true, index: true
      t.string     :share_token
      t.text       :curation_criteria

      t.timestamps
    end
    
    add_index :portfolios, :name, unique: true
    add_index :portfolios, :share_token, unique: true
  end
end

class CreatePortfolioItems < ActiveRecord::Migration[7.0]
  def change
    create_table :portfolio_items do |t|
      t.string :comment
      t.integer :position
      t.references :portfolio, null: false, foreign_key: true
      t.references :photo, null: false, foreign_key: true

      t.timestamps
    end
  end
end

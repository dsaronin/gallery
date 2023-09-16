class CreatePortfolios < ActiveRecord::Migration[7.0]
  def change
    create_table :portfolios do |t|
      t.string :name
      t.string :title

      t.timestamps
    end
    add_index :portfolios, :name, unique: true
  end
end

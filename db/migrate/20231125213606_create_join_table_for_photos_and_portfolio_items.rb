class CreateJoinTableForPhotosAndPortfolioItems < ActiveRecord::Migration[7.0]
  def change
    create_join_table :photos, :portfolio_items
  end
end

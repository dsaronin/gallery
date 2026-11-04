class AddForeignKeyToExhibitionsForShowing < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :exhibitions, :showings, column: :showing_id
  end
end

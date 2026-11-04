class CreateExhibitions < ActiveRecord::Migration[7.1]
  def change
    create_table :exhibitions do |t|
      t.string     :title, null: false
      t.integer    :status, null: false, default: 0
      t.integer    :sales_policy, null: false, default: 0
      t.integer    :budget
      t.integer    :total_expenses
      t.date       :approved_by_artist_at
      t.date       :approved_by_venue_at
      t.bigint     :showing_id
      t.references :portfolio, null: false, foreign_key: true, index: true
      t.references :venue, null: false, foreign_key: true, index: true
      t.references :placard, foreign_key: true, index: true
      t.references :talent, foreign_key: true, index: true

      t.timestamps
    end

    add_index :exhibitions, :showing_id
  end
end

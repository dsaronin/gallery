class CreateShowings < ActiveRecord::Migration[7.1]
  def change
    create_table :showings do |t|
      t.string     :title
      t.integer    :status, null: false, default: 0
      t.date       :start_date, null: false
      t.date       :end_date, null: false
      t.integer    :prep_days, null: false, default: 1
      t.integer    :teardown_days, null: false, default: 1
      t.integer    :rental_cost
      t.datetime   :reception_date
      t.integer    :visitation_count, null: false, default: 0
      t.text       :notes
      t.references :exhibition, null: false, foreign_key: true, index: true
      t.references :venue, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end

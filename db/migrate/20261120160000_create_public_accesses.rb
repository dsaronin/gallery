class CreatePublicAccesses < ActiveRecord::Migration[7.1]
  def change
    create_table :public_accesses do |t|
      t.string   :label, null: false
      t.string   :token, null: false
      t.integer  :access_scope, null: false, default: 0
      t.date     :expires_at
      t.datetime :revoked_at
      t.text     :notes

      t.timestamps
    end

    add_index :public_accesses, :token, unique: true
    add_index :public_accesses, :access_scope
    add_index :public_accesses, :revoked_at
  end
end

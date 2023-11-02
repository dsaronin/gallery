class CreateFolders < ActiveRecord::Migration[7.0]
  def change
    create_table :folders do |t|
      t.string :fname
      t.string :fpath

      t.timestamps
    end
    add_index :folders, :fname, unique: true
  end
end

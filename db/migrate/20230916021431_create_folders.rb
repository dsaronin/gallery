class CreateFolders < ActiveRecord::Migration[7.0]
  def change
    create_table :folders do |t|
      t.string :name
      t.string :path

      t.timestamps
    end
    add_index :folders, :name, unique: true
  end
end

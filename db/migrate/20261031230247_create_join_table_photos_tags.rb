class CreateJoinTablePhotosTags < ActiveRecord::Migration[7.1]
  def change
    create_join_table :photos, :tags do |t|
      t.index [:photo_id, :tag_id], unique: true
      t.index [:tag_id, :photo_id]
    end
  end
end

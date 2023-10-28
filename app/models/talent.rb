class Talent < ApplicationRecord
  has_many :photos
end

# -----------------------------
#      t.string :talent_code
#      t.string :talent_name
#      t.string :talent_nbr
#      t.string :first_name
#      t.string :last_name
#      t.string :gender
#      t.integer :shoot_age
#      t.date :talent_release
# -----------------------------

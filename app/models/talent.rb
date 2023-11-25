class Talent < ApplicationRecord
  has_many :photos
  has_one  :cover, class_name: "Photo"
end

# -----------------------------
#      t.string :talent_code
#      t.string :talent_nbr
#      t.string :talent_name
#      t.string :first_name
#      t.string :last_name
#      t.date :talent_dob
#      t.date :talent_release
# -----------------------------

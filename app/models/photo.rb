class Photo < ApplicationRecord
  belongs_to :talent
  belongs_to :photoshoot
end

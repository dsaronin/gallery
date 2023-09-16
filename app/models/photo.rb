class Photo < ApplicationRecord
  belongs_to :folder
  belongs_to :portfolio, optional: true
  belongs_to :talent, optional: true
end

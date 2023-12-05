class PortfolioItem < ApplicationRecord
  belongs_to :portfolio
  has_one :photo
  acts_as_list 
end

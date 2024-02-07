# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2024 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

class Portfolio < ApplicationRecord
  has_many  :portfolio_items

# ----------------------------------------------------------
#      t.string :name
#      t.string :title
# ----------------------------------------------------------


end

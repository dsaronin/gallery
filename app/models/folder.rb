# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2023 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

class Folder < ApplicationRecord

  has_many :photos

  validates_presence_of  :name
  validates_presence_of  :path

# ------------------------------------------------------------------------------
#      t.string :name
#      t.string :path
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
#
end  # class

# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2023 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

class Folder < ApplicationRecord

  has_many :photos, dependent: :destroy

  validates_presence_of  :fname
  validates_presence_of  :fpath

# ------------------------------------------------------------------------------
#      t.string :fname
#      t.string :fpath
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
#
end  # class

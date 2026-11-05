# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2023 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

class Catalog < ApplicationRecord

  has_many :photos, dependent: :destroy

  validates_presence_of  :fname
  validates_presence_of  :fpath

# ------------------------------------------------------------------------------
#      t.string :fname
#      t.string :fpath
# ------------------------------------------------------------------------------
  def self.dashboard_metrics
    available_disk_count = begin
      # Uses CatalogHelper logic or inspects source directory
      picpath = File.join(Rails.configuration.photo_path, Rails.configuration.photo_base)
      picglob = File.join(picpath, "**", Rails.configuration.photo_source)
      Dir[picglob].size
    rescue
      0
    end

    {
      ingested_count: count,
      available_disk_count: available_disk_count,
      indexed_photos_count: Photo.active_candidates.count
    }
  end

# ------------------------------------------------------------------------------
#
end  # class

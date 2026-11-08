# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2023 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

class Catalog < ApplicationRecord

  belongs_to :talent, optional: true
  has_many :photos, dependent: :destroy

  validates :name, presence: true
  validates :fname, presence: true, uniqueness: true
  validates_presence_of  :fpath

  before_validation :set_default_name

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
  private

  def set_default_name
    self.name = File.basename(fname.to_s) if name.blank? && fname.present?
  end
# ------------------------------------------------------------------------------
#
end  # class

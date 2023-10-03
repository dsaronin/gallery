class FolderController < ApplicationController
  include FolderHelper

  # GALLERY_PATH, GALLERY_BASE, GALLERY_SOURCE
  # Rails.configuration.photo_path  -- string for basic path to photos: ex $HOME
  # Rails.configuration.photo_base  -- string for photos folder: ex Pictures
  # Rails.configuration.photo_source  -- string for subdirectories containing photos for sourcing: ex darktable_exported
  #

  def index
  end

  def show
  end

  def selectfolder
    @folders = picture_source_folders
  end

  def loadphotos
    
    folder = params[:folder]
    dirpath = file_to_path( folder )
    Dir.exist?(dirpath)
    photos = Dir.glob("*.jpg")  # {jpg¸ JPEG}
    photos.each do |photofile|
      f = File.new( photofile )
      f.birthtime   # time for creation of file
      meta = Exiftool.new( photofile )
      m = meta.to_hash
      # m[ :longitude ] ... etc
      # photodatetime
      # width
      # height
    end

  end
end

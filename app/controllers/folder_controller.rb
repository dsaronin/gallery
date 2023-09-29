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
    # params[:folder] has the selection
    # steps
    # validate path = picpath + folder + photo_source
    # @photos <= get all jpg children in folder
    # @photos.each { get file info, exifinfo; create a photo rec, save}
    #
  end
end

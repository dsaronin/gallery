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
    # puts "LOADPHOTOS folder: #{folder}, path: #{dirpath}"

    if Dir.exist?(dirpath)
      @photos = Dir.glob( File.join(dirpath, "*.jpg") )  # {jpg¸ JPEG}

      @photos.each do |photofile|
        f = File.new( photofile )
        birth = f.birthtime   # time for creation of file
        meta = Exiftool.new( photofile )
        m = meta.to_hash
        lat =    m[:gps_latitude ]
        long =   m[:gps_longitude ]
        dtime =  m[:create_date ]
        width =  m[:image_width ]
        height = m[:image_height ]
        break
      end
    else
      puts "LOADPATH path doesn't exist"
    end

  end
end

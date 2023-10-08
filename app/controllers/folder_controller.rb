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
    
    my_folder = params[:folder]
    dirpath = file_to_path( my_folder )
    folder = Folder.create( name: my_folder, path: dirpath )

    # puts "LOADPHOTOS folder: #{my_folder}, path: #{dirpath}"

    if Dir.exist?(dirpath)
      @photos = Dir.glob( File.join(dirpath, "*.jpg") )  # {jpg¸ JPEG}
      meta_all = Exiftool.new( @photos )

      @photos.each do |photofile|
        f = File.new( photofile )
        birth = f.birthtime   # time for creation of file
        m = meta_all.result_for( photofile ).to_hash
        lat =    m[:gps_latitude ]
        long =   m[:gps_longitude ]
        dtime =  m[:create_date ]
        width =  m[:image_width ]
        height = m[:image_height ]
        dsc = fn_to_dsc( photofile, dirpath )
        puts "LOADPHOTOS: #{photofile}, #{dsc}, #{dtime}, #{width}, #{height}"
        @pic = folder.photos.create!(
          photo_dsc: dsc,
          filename: photofile,
          photodate: dtime.sub(/:/,"/").sub(/:/,"/").to_datetime,
          latitude: lat, longitude: long,
          width: width, height: height
        )
        break
      end
    else
      puts "LOADPATH path doesn't exist"
    end

  end
end
#      :photo_dsc
#      :filename
#      :rating
#      :photodate
#      :latitude
#      :longitude
#      :width
#      :height
#

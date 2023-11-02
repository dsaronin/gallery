class FolderController < ApplicationController
  include FolderHelper
  before_action :validate_folder, :only => [:show]
 
# ----------------------------------------------------------
  # GALLERY_PATH, GALLERY_BASE, GALLERY_SOURCE
  # Rails.configuration.photo_path  -- string for basic path to photos: ex $HOME
  # Rails.configuration.photo_base  -- string for photos folder: ex Pictures
  # Rails.configuration.photo_source  -- string for subdirectories containing photos for sourcing: ex darktable_exported
# ----------------------------------------------------------
# index -- show all loaded folders; allow user to select one
# ----------------------------------------------------------
  def index
    @list = Folder.all
  end

# ----------------------------------------------------------
# show  -- show thumbnail pics of all photos in selected folder
# ----------------------------------------------------------
  def show
  end

# ----------------------------------------------------------
# selectfolder  -- show all non-loaded pic folders; all user to select one
# ----------------------------------------------------------
  def selectfolder
    folders = Folder.all
    @folder_list = folders.map {|f| f.fname}
    @folders = picture_source_folders - @folder_list
  end

# ----------------------------------------------------------
# loadphotos  -- loads into db all photos from the selected folder
# ----------------------------------------------------------
  def loadphotos
    
    @my_folder = params[:folder]
    dirpath = file_to_path( @my_folder )
    folder = Folder.create( fname: @my_folder, fpath: dirpath )

    # puts "LOADPHOTOS folder: #{@my_folder}, fpath: #{dirpath}"

    if Dir.exist?(dirpath)
      @photos = Dir.glob( File.join(dirpath, "*.jpg") )  # {jpg¸ JPEG}
      meta_all = Exiftool.new( @photos )

      @photos.each do |photofile|
        f = File.new( photofile )
        birth = f.ctime   # time for creation of file
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
          filename: filepath_to_fn(photofile),
          photodate: dtime.sub(/:/,"/").sub(/:/,"/").to_datetime,
          latitude: lat, longitude: long,
          width: width, height: height
        )
      end
    else
      puts "LOADPATH path doesn't exist"
      @fail = true
    end
  end

# ----------------------------------------------------------
# update  -- rechecks a folder for any recent unload pics & loads them
# ----------------------------------------------------------
# ----------------------------------------------------------
# destroy  -- destorys a folder (from db) and all its related pics
# ----------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
  def validate_folder()
    @folder = Folder.find(params[:id])
    true     # returning true continues controller action
    
  rescue ActiveRecord::RecordNotFound
    puts "SHOW: ERROR NOT FOUND"
      flash[:notice] = "folder doesn't exist"
      flash[:show_flash] = true
      # redirect_back
      false
  end

# ------------------------------------------------------------------------------


# ----------------------------------------------------------
end    # class controller

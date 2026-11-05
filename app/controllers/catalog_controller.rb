# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2024 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

class CatalogController < ApplicationController
  include CatalogHelper
  before_action :validate_catalog, :only => [:show]
 
# ----------------------------------------------------------
  # GALLERY_PATH, GALLERY_BASE, GALLERY_SOURCE
  # Rails.configuration.photo_path  -- string for basic path to photos: ex $HOME
  # Rails.configuration.photo_base  -- string for photos catalog: ex Pictures
  # Rails.configuration.photo_source  -- string for subdirectories containing photos for sourcing: ex darktable_exported
# ----------------------------------------------------------
# index -- show all loaded catalogs; allow user to select one
# ----------------------------------------------------------
  def index
    @list = Catalog.all
  end

# ----------------------------------------------------------
# show  -- show thumbnail pics of all photos in selected catalog
# ----------------------------------------------------------
  def show
  end

# ----------------------------------------------------------
# selectcatalog  -- show all non-loaded pic catalogs; all user to select one
# ----------------------------------------------------------
  def selectcatalog
    catalogs = Catalog.all
    @catalog_list = catalogs.map {|f| f.fname}
    @catalogs = picture_source_catalogs - @catalog_list
  end

# ----------------------------------------------------------
# loadphotos  -- loads into db all photos from the selected catalog
# ----------------------------------------------------------
  def loadphotos
    
    @my_catalog = params[:catalog]
    dirpath = file_to_path( @my_catalog )
    catalog = Catalog.find_or_create_by!( fname: @my_catalog ) do |f|
      f.fpath = dirpath
    end

    # Session state hook
    gallery_state.current_catalog_id = catalog.id

    # puts "LOADPHOTOS catalog: #{@my_catalog}, fpath: #{dirpath}"

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

        target_fn = filepath_to_fn(photofile)
        next if catalog.photos.exists?(filename: target_fn)

        @pic = catalog.photos.create!(
          photo_dsc: dsc,
          filename: target_fn,
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
# update  -- rechecks a catalog for any recent unload pics & loads them
# ----------------------------------------------------------
# ----------------------------------------------------------
# destroy  -- destorys a catalog (from db) and all its related pics
# ----------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
  def validate_catalog()
    @catalog = Catalog.find(params[:id])
    gallery_state.current_catalog_id = @catalog.id
    true     # returning true continues controller action
    
  rescue ActiveRecord::RecordNotFound
    puts "SHOW: ERROR NOT FOUND"
      flash[:notice] = "catalog doesn't exist"
      flash[:show_flash] = true
      # redirect_back
      false
  end

# ------------------------------------------------------------------------------


# ----------------------------------------------------------
end    # class controller

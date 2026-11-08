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
# selectcatalog  -- show all non-loaded pic catalogs; allow user to select one
# ----------------------------------------------------------
  def selectcatalog
    catalogs = Catalog.all
    @catalog_list = catalogs.map(&:fname)
    available = (picture_source_catalogs - @catalog_list).sort

    # Group by top-level bucket (e.g. "DarkFire Photography", "pix", etc.)
    @grouped_catalogs = available.group_by do |path|
      parts = path.split(File::SEPARATOR)
      parts.size > 1 ? parts.first : "(Root)"
    end
  end
# ----------------------------------------------------------
# loadphotos  -- loads into db all photos from the selected catalog
# ----------------------------------------------------------
  def loadphotos
    @my_catalog = params[:catalog]
    custom_name = params[:name].presence

    if @my_catalog.blank?
      flash[:alert] = "No catalog folder selected."
      flash[:show_flash] = true
      redirect_to catalog_index_path and return
    end

    dirpath = file_to_path(@my_catalog)

    # Policy A: Directory must exist and contain at least one JPEG
    unless Dir.exist?(dirpath)
      flash[:alert] = "Ingestion aborted: Directory '#{dirpath}' does not exist."
      flash[:show_flash] = true
      redirect_to catalog_index_path and return
    end

    photo_files = Dir.glob(File.join(dirpath, "*.{jpg,JPG,jpeg,JPEG}"))
    if photo_files.empty?
      flash[:alert] = "Ingestion aborted: No JPEG images found in '#{@my_catalog}'."
      flash[:show_flash] = true
      redirect_to catalog_index_path and return
    end

    # Persist catalog record only after verifying valid image set
    catalog = Catalog.find_or_create_by!(fname: @my_catalog) do |c|
      c.fpath = dirpath
      c.name  = custom_name if custom_name.present?
    end

    # Update session state hook
    gallery_state.current_catalog_id = catalog.id

    meta_all = Exiftool.new(photo_files)
    ingested_count = 0

    photo_files.each do |photofile|
      target_fn = filepath_to_fn(photofile)
      next if catalog.photos.exists?(filename: target_fn)

      m = meta_all.result_for(photofile).to_hash
      lat   = m[:gps_latitude]
      long  = m[:gps_longitude]
      dtime = m[:create_date]
      width = m[:image_width]
      height = m[:image_height]
      dsc   = fn_to_dsc(photofile, dirpath)

      photo_date = if dtime.present?
                     dtime.to_s.sub(/:/, "/").sub(/:/, "/").to_datetime rescue nil
                   end

      catalog.photos.create!(
        photo_dsc: dsc,
        filename: target_fn,
        photodate: photo_date,
        latitude: lat,
        longitude: long,
        width: width,
        height: height
      )
      ingested_count += 1
    end

    flash[:notice] = "Ingested catalog '#{catalog.name}' (#{ingested_count} photos loaded)."
    flash[:show_flash] = true
    redirect_to catalog_index_path
  end

# ----------------------------------------------------------
# update  -- rechecks a catalog for any recent unload pics & loads them
# ----------------------------------------------------------

def update
    @catalog = Catalog.find(params[:id])

    if @catalog.update(catalog_params)
      flash[:notice] = if @catalog.talent_id.present?
                         "Assigned talent '#{@catalog.talent.talent_name}' to catalog '#{@catalog.name}'."
                       else
                         "Removed talent assignment from catalog '#{@catalog.name}'."
                       end
      flash[:show_flash] = true
      redirect_to catalog_index_path
    else
      flash[:alert] = "Failed to update catalog: #{@catalog.errors.full_messages.join(', ')}"
      flash[:show_flash] = true
      redirect_to catalog_index_path
    end
  end

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

  private

  def catalog_params
    params.require(:catalog).permit(:name, :talent_id)
  end


# ----------------------------------------------------------
end    # class controller

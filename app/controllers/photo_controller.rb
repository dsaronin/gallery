class PhotoController < ApplicationController
    before_action :validate_photo, :only => [:show, :update, :assign_tag, :remove_tag]
 
  def index
  end

  def show
    @assigned_tags = @photo.tags.includes(:category).order("categories.name, tags.name")
    @categories    = Category.includes(:tags).order(:name)
    @available_tags = Tag.where.not(id: @photo.tag_ids).order(:name)
  end

  def update
    if @photo.update(photo_params)
      respond_to do |format|
        format.turbo_stream
        format.html do
          if turbo_frame_request?
            render partial: "photo/star_rating", locals: { photo: @photo }
          else
            redirect_back fallback_location: folder_path(@photo.folder)
          end
        end
      end
    else
      head :unprocessable_entity
    end
  end

  def assign_tag
    tag = Tag.find(params[:tag_id])
    @photo.tags << tag unless @photo.tags.include?(tag)
    gallery_state.set_active_tag!(tag)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to photo_path(@photo) }
    end
  end

  def remove_tag
    tag = Tag.find(params[:tag_id])
    @photo.tags.destroy(tag)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to photo_path(@photo) }
    end
  end

  private

  def photo_params
    params.require(:photo).permit(:stars, :photo_dsc, :notes, :talent_id)
  end

# ------------------------------------------------------------------------------
  def validate_photo()
    @photo = Photo.find(params[:id])
    true     # returning true continues controller action
    
  rescue ActiveRecord::RecordNotFound
    puts "SHOW: ERROR NOT FOUND"
      flash[:notice] = "photo not found"
      flash[:show_flash] = true
      redirect_back fallback_location: root_path
      false
  end

# ------------------------------------------------------------------------------

end   # controller

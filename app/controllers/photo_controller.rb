class PhotoController < ApplicationController
    before_action :validate_photo, :only => [:show, :update]
 
  def index
  end

  def show
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
      flash[:notice] = "photo doesn't exist"
      flash[:show_flash] = true
      redirect_back fallback_location: root_path
      false
  end

# ------------------------------------------------------------------------------

end   # controller

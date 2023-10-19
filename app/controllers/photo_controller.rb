class PhotoController < ApplicationController
    before_action :validate_photo, :only => [:show]
 
  def index
  end

  def show
  end
# ------------------------------------------------------------------------------
  def validate_photo()
    @photo = Photo.find(params[:id])
    true     # returning true continues controller action
    
  rescue ActiveRecord::RecordNotFound
    puts "SHOW: ERROR NOT FOUND"
      flash[:notice] = "photo doesn't exist"
      flash[:show_flash] = true
      # redirect_back
      false
  end

# ------------------------------------------------------------------------------

end

class TagController < ApplicationController
  def index
    @categories = Category.includes(:tags).order(:name)

    # Determine default/sticky category
    active_id = gallery_state.current_category_id
    unless active_id && @categories.exists?(id: active_id)
      active_id = @categories.first&.id
    end
    gallery_state.current_category_id = active_id
    @selected_category_id = active_id

    @new_category = Category.new
    @new_tag = Tag.new(category_id: @selected_category_id)
  end

  def create
    @tag = Tag.new(tag_params)
    if @tag.save
      gallery_state.current_category_id = @tag.category_id
      flash[:notice] = "Tag '#{@tag.name}' created."
    else
      flash[:alert] = @tag.errors.full_messages.to_sentence
    end
    redirect_to tag_index_path
  end

  def destroy
    @tag = Tag.find(params[:id])
    @tag.destroy
    flash[:notice] = "Tag '#{@tag.name}' deleted."
    redirect_to tag_index_path
  end

  private

  def tag_params
    params.require(:tag).permit(:category_id, :name, :theme)
  end

end  # controller

class TagController < ApplicationController
  def index
    @categories = Category.includes(:tags).order(:name)

    # 1. Resolve and validate active category
    active_cat_id = gallery_state.current_category_id
    unless active_cat_id && @categories.any? { |c| c.id == active_cat_id }
      active_cat_id = @categories.first&.id
    end
    gallery_state.current_category_id = active_cat_id
    @selected_category_id = active_cat_id

    # 2. Resolve and validate active tag for the selected category
    active_category = @categories.find { |c| c.id == active_cat_id }
    available_tags  = active_category ? active_category.tags.sort_by(&:name) : []

    active_tag_id = gallery_state.current_tag_id
    selected_tag  = available_tags.find { |t| t.id == active_tag_id } || available_tags.first

    if selected_tag
      gallery_state.set_active_tag!(selected_tag)
      @selected_tag_id = selected_tag.id
    else
      gallery_state.current_tag_id = nil
      @selected_tag_id = nil
    end

    @new_category = Category.new
    @new_tag = Tag.new(category_id: @selected_category_id)
  end

  def create
    @tag = Tag.new(tag_params)
    if @tag.save
      gallery_state.set_active_tag!(@tag)
      flash[:notice] = "Tag '#{@tag.name}' created."
    else
      flash[:alert] = @tag.errors.full_messages.to_sentence
    end
    redirect_to tag_index_path
  end

  def destroy
    @tag = Tag.find(params[:id])
    was_active = (gallery_state.current_tag_id == @tag.id)
    @tag.destroy

    gallery_state.current_tag_id = nil if was_active
    flash[:notice] = "Tag '#{@tag.name}' deleted."
    redirect_to tag_index_path
  end

  private

  def tag_params
    params.require(:tag).permit(:category_id, :name, :theme)
  end

end  # controller

class CategoryController < ApplicationController
  def create
    @category = Category.new(category_params)
    if @category.save
      gallery_state.current_category_id = @category.id
      flash[:notice] = "Category '#{@category.name}' created."
    else
      flash[:alert] = @category.errors.full_messages.to_sentence
    end
    redirect_to tag_index_path
  end

  def update
    @category = Category.find(params[:id])
    if @category.update(category_params)
      flash[:notice] = "Category updated."
    else
      flash[:alert] = @category.errors.full_messages.to_sentence
    end
    redirect_to tag_index_path
  end

  def destroy
    @category = Category.find(params[:id])
    @category.destroy
    if gallery_state.current_category_id == @category.id
      gallery_state.current_category_id = nil
    end
    flash[:notice] = "Category '#{@category.name}' deleted."
    redirect_to tag_index_path
  end

  private

  def category_params
    params.require(:category).permit(:name)
  end
end

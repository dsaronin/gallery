# frozen_string_literal: true

# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2026 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

# app/controllers/exhibition_controller.rb
class ExhibitionController < ApplicationController
  before_action :set_exhibition, only: %i[show edit update destroy]

  def index
    @exhibitions = Exhibition.includes(:portfolio, :venue).order(created_at: :desc)
  end

  def show
    gallery_state.current_exhibition_id = @exhibition.id
    @exhibition_items = @exhibition.exhibition_items.includes(:photo, :placard).order(:position)
  end

  def new
    @exhibition = Exhibition.new(status: :draft, sales_policy: :not_for_sale)
  end

  def create
    @exhibition = Exhibition.new(exhibition_params)

    if @exhibition.save
      gallery_state.current_exhibition_id = @exhibition.id
      redirect_to exhibition_path(@exhibition), notice: "Exhibition \"#{@exhibition.title}\" created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @exhibition.update(exhibition_params)
      redirect_to exhibition_path(@exhibition), notice: "Exhibition \"#{@exhibition.title}\" updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    exhibition_title = @exhibition.title
    if @exhibition.destroy
      gallery_state.current_exhibition_id = nil if gallery_state.current_exhibition_id == @exhibition.id
      redirect_to exhibition_index_path, notice: "Exhibition \"#{exhibition_title}\" was removed."
    else
      redirect_to exhibition_path(@exhibition), alert: @exhibition.errors.full_messages.to_sentence
    end
  end

  # DELETE /exhibition/:id/clear_items
  def clear_items
    @exhibition = Exhibition.find(params[:id])
    @exhibition.exhibition_items.destroy_all
    @exhibition.update!(curation_criteria: nil)

    redirect_to @exhibition, notice: "Exhibition cleared: all photos removed and curation criteria reset."
  end

  private

  def set_exhibition
    @exhibition = Exhibition.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to exhibition_index_path, alert: "Exhibition not found."
  end

  def exhibition_params
    params.require(:exhibition).permit(
      :title,
      :status,
      :sales_policy,
      :budget,
      :total_expenses,
      :approved_by_artist_at,
      :approved_by_venue_at,
      :portfolio_id,
      :venue_id,
      :placard_id,
      :talent_id,
      :showing_id
    )
  end
end  # class

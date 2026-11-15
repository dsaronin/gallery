# frozen_string_literal: true

# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2026 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

# app/controllers/showing_controller.rb
class ShowingController < ApplicationController
  before_action :set_showing, only: %i[show edit update destroy]
  before_action :load_collections, only: %i[new create edit update]

  def index
    @showings = Showing.includes(:venue, exhibition: :photos).order(start_date: :asc, created_at: :desc)
  end

  def show
    gallery_state.current_showing_id = @showing.id
  end

  def new
    @showing = Showing.new(
      status: :scheduled,
      prep_days: ::Gallery::Environ::DEFAULT_PREP_DAYS,
      teardown_days: ::Gallery::Environ::DEFAULT_TEARDOWN_DAYS,
      visitation_count: 0
    )
  end

  def create
    @showing = Showing.new(showing_params)

    if @showing.save
      gallery_state.current_showing_id = @showing.id
      redirect_to showing_path(@showing), notice: "Showing \"#{@showing.title}\" created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @showing.update(showing_params)
      redirect_to showing_path(@showing), notice: "Showing \"#{@showing.title}\" updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    showing_title = @showing.title
    showing_id    = @showing.id

    if @showing.destroy
      gallery_state.current_showing_id = nil if gallery_state.current_showing_id == showing_id
      redirect_to showing_index_path, notice: "Showing \"#{showing_title}\" was removed."
    else
      redirect_to showing_path(@showing), alert: @showing.errors.full_messages.to_sentence
    end
  end

  private

  def set_showing
    @showing = Showing.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to showing_index_path, alert: "Showing not found."
  end

  def load_collections
    @exhibitions = Exhibition.order(:title)
    @venues      = Venue.order(:name)
  end

  def showing_params
    params.require(:showing).permit(
      :title,
      :status,
      :start_date,
      :end_date,
      :prep_days,
      :teardown_days,
      :rental_cost,
      :reception_date,
      :visitation_count,
      :notes,
      :exhibition_id,
      :venue_id
    )
  end
end  # class

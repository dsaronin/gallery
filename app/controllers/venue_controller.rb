# frozen_string_literal: true

# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2026 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

# app/controllers/venue_controller.rb
class VenueController < ApplicationController
  before_action :set_venue, only: %i[show edit update destroy]

  def index
    @venues = Venue.order(created_at: :desc)
  end

  def show
    gallery_state.current_venue_id = @venue.id
  end

  def new
    @venue = Venue.new(venue_type: :commercial_gallery, status: :pending)
  end

  def create
    @venue = Venue.new(venue_params)

    if @venue.save
      gallery_state.current_venue_id = @venue.id
      redirect_to venue_path(@venue), notice: "Venue \"#{@venue.name}\" created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @venue.update(venue_params)
      redirect_to venue_path(@venue), notice: "Venue \"#{@venue.name}\" updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    venue_name = @venue.name
    venue_id   = @venue.id

    if @venue.destroy
      gallery_state.current_venue_id = nil if gallery_state.current_venue_id == venue_id
      redirect_to venue_index_path, notice: "Venue \"#{venue_name}\" was removed."
    else
      redirect_to venue_path(@venue), alert: @venue.errors.full_messages.to_sentence
    end
  end

  private

  def set_venue
    @venue = Venue.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to venue_index_path, alert: "Venue not found."
  end

  def venue_params
    params.require(:venue).permit(
      :name,
      :venue_type,
      :status,
      :space_name,
      :wall_linear_meters,
      :rate_per_day,
      :address,
      :contact_name,
      :contact_position,
      :contact_email,
      :contact_phone,
      :website_url,
      :notes
    )
  end
end   # class

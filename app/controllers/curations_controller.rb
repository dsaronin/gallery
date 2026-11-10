# frozen_string_literal: true

# -----------------------------------------------------------------------------
# GALLERY: Curations Controller
# File: app/controllers/curations_controller.rb
#
# PURPOSE:
# Polymorphic staging workspace controller managing photo curation for both
# Portfolio and Exhibition target objects.
# -----------------------------------------------------------------------------

class CurationsController < ApplicationController
  before_action :set_curatable
  before_action :load_filter_options

  # GET /portfolios/:portfolio_id/curation
  # GET /exhibitions/:exhibition_id/curation
  def show
    @criteria = @curatable.curation_criteria
    @query = PhotoQuery.new(@criteria, limit: @curatable.max_curation_size)
    @candidates = @query.resolve
    @count = @candidates.size
    @exceeds_capacity = @query.exceeds_capacity?
  end

  # POST /portfolios/:portfolio_id/curation/preview
  # Responds to Turbo Frame updates as the user adjusts filters
  def preview
    @criteria = Gallery::CurationCriteria.new(curation_params)
    @query = PhotoQuery.new(@criteria, limit: @curatable.max_curation_size)
    @candidates = @query.resolve
    @count = @candidates.size
    @exceeds_capacity = @query.exceeds_capacity?

    respond_to do |format|
      format.turbo_stream
      format.html { render :show }
    end
  end

  # POST /portfolios/:portfolio_id/curation/commit
  # Persists criteria recipe and batch-inserts candidates into join table
  def commit
    @criteria = Gallery::CurationCriteria.new(curation_params)
    @curatable.curation_criteria = @criteria

    if @curatable.save
      added = @curatable.curate_photos!(limit: @curatable.max_curation_size)
      redirect_to @curatable, notice: "Curation recipe applied: #{added} photos added to #{@curatable.class.model_name.human}."
    else
      flash.now[:alert] = "Failed to save curation criteria: #{@curatable.errors.full_messages.to_sentence}"
      @query = PhotoQuery.new(@criteria, limit: @curatable.max_curation_size)
      @candidates = @query.resolve
      @count = @candidates.size
      @exceeds_capacity = @query.exceeds_capacity?
      render :show, status: :unprocessable_entity
    end
  end

  # DELETE /portfolios/:portfolio_id/curation/clear
  # Resets the criteria recipe on the curatable object
  def clear
    @curatable.curation_criteria = Gallery::CurationCriteria.new
    @curatable.save!
    redirect_to polymorphic_path([@curatable, :curation]), notice: "Curation criteria cleared."
  end

  private

  def set_curatable
    if params[:portfolio_id]
      @curatable = Portfolio.find(params[:portfolio_id])
    elsif params[:exhibition_id]
      @curatable = Exhibition.find(params[:exhibition_id])
    else
      redirect_to root_path, alert: "No curation target specified."
    end
  end

  def load_filter_options
    @catalogs    = Catalog.order(:name)
    @portfolios  = Portfolio.where.not(id: (@curatable.id if @curatable.is_a?(Portfolio))).order(:title)
    @exhibitions = Exhibition.where.not(id: (@curatable.id if @curatable.is_a?(Exhibition))).order(:title)
    @categories  = Category.includes(:tags).order(:name)
    @talents     = Talent.order(:talent_name)
  end

  def curation_params
    params.fetch(:curation_criteria, {}).permit(
      :min_stars,
      :exact_stars,
      sources: [catalog_ids: [], portfolio_ids: [], exhibition_ids: []],
      tag_ids: [],
      talent_ids: [],
      date_range: [:start_date, :end_date]
    )
  end
end

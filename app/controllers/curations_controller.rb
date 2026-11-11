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
    session_state = ::Gallery::Environ::SessionState.load(session)
    criteria = session_state.staged_criteria_for(@curatable)

    build_curation_workspace(criteria)
  end

  # POST /portfolios/:portfolio_id/curation/preview
  # Responds to Turbo Frame updates as the user adjusts filters
  def preview
    criteria = ::Gallery::CurationCriteria.new(curation_params)

    session_state = ::Gallery::Environ::SessionState.load(session)
    session_state.stage_criteria!(@curatable, criteria)
    session_state.persist!(session)

    build_curation_workspace(criteria)

    respond_to do |format|
      format.turbo_stream
      format.html { render :show }
    end
  end

  # POST /portfolios/:portfolio_id/curation/commit
  # Persists criteria recipe and batch-inserts candidates into join table
  def commit
    query = PhotoQuery.new(@curatable.curation_criteria, limit: @curatable.max_curation_size)

    if query.ingestible?
      # Read existing history array, ensuring backwards compatibility if previously a single hash/object
      existing_history = Array.wrap(@curatable.read_attribute(:curation_criteria)).compact
      existing_history << @criteria.as_json

      @curatable.curation_criteria = existing_history
      @curatable.save!

      added = @curatable.curate_photos!(limit: @curatable.max_curation_size)
      redirect_to @curatable, notice: "Curation complete: #{added} #{'photo'.pluralize(added)} added to #{@curatable.class.model_name.human}."
    else
      flash[:alert] = "Cannot ingest: criteria matches #{query.count} photos (limit: #{@curatable.max_curation_size})."
      redirect_to polymorphic_path([@curatable, :curation])
    end
  end

  # DELETE /portfolios/:portfolio_id/curation/clear
  # Resets the criteria recipe on the curatable object
  def clear
    session_state = ::Gallery::Environ::SessionState.load(session)
    session_state.clear_staged_criteria!(@curatable)
    session_state.persist!(session)

    redirect_to polymorphic_path([@curatable, :curation]), notice: "Staged curation criteria cleared."
  end

  private

  def build_curation_workspace(criteria)
    @criteria = criteria
    @query = PhotoQuery.new(@criteria, limit: @curatable.max_curation_size)
    @count = @query.count
    @exceeds_capacity = @query.exceeds_capacity?
    @candidates = @exceeds_capacity ? Photo.none : @query.resolve
    @ingestible = @query.ingestible?
  end

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

end   # class

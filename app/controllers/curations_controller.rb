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

    Rails.logger.debug { ">>> [PREVIEW] Staged criteria hash: #{criteria.to_h.inspect}" }
    Rails.logger.debug { ">>> [PREVIEW] Staged criteria active?: #{criteria.active?}" }

    build_curation_workspace(criteria)

    respond_to do |format|
      format.turbo_stream
      format.html { render :show }
    end
  end

  # POST /portfolios/:portfolio_id/curation/commit
  # Persists criteria recipe and batch-inserts candidates into join table
  def commit
    session_state = ::Gallery::Environ::SessionState.load(session)
    staged_criteria = session_state.staged_criteria_for(@curatable)

    Rails.logger.debug { ">>> [COMMIT] Session raw: #{session[:gallery_state].inspect}" }
    Rails.logger.debug { ">>> [COMMIT] Retrieved staged criteria: #{staged_criteria.inspect}" }
    Rails.logger.debug { ">>> [COMMIT] Staged criteria active?: #{staged_criteria.active?}" }

    if staged_criteria.blank? || !staged_criteria.active?
      redirect_to polymorphic_path([@curatable, :curation]), alert: "No active filter criteria staged to ingest."
      return
    end

    added_count = @curatable.curate_photos!(staged_criteria)

    session_state.clear_staged_criteria!(@curatable)
    session_state.persist!(session)

    notice_msg = "Ingested #{added_count} #{'photo'.pluralize(added_count)} into #{@curatable.class.model_name.human.downcase}."
    redirect_to @curatable, notice: notice_msg
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

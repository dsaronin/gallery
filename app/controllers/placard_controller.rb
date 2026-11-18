# frozen_string_literal: true

# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2026 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

# app/controllers/placard_controller.rb
class PlacardController < ApplicationController
  ALLOWED_TARGET_TYPES = %w[Portfolio Exhibition PortfolioItem ExhibitionItem].freeze

  before_action :set_placard, only: %i[edit update destroy]
  before_action :resolve_context, only: %i[show itemcard display]

  # GET /placard
  # Lists MD cards for all <Collection>s (Portfolios and Exhibitions)
  def index
    @portfolios  = Portfolio.includes(:placard, :portfolio_items).order(created_at: :desc)
    @exhibitions = Exhibition.includes(:placard, :portfolio, :exhibition_items).order(created_at: :desc)
    @collections = (@portfolios.to_a + @exhibitions.to_a)
  end

  # GET /placard/:id or GET /placard/collection_show?target_type=...&target_id=...
  # Upper area: <Collection> placard summary; Lower area: <CollectionItem> pseudo-placard thumbnails
  def show
    @collection = resolve_collection_from_context!
    return unless @collection

    @collection_placard_data = @collection.placard_data
    @collection_items = @collection.items_association.includes(:photo, :placard)
    @item_entries = @collection_items.map do |item|
      {
        item:         item,
        photo:        item.photo,
        placard:      item.placard,
        placard_data: item.placard_data
      }
    end
  end

  # GET /placard/:id/itemcard or GET /placard/itemcard?target_type=...&target_id=...
  # Displays full administrative MD card with :direct vs :cascaded provenance
  def itemcard
    return unless @target || @placard

    @target ||= inferred_owner_for(@placard)
    @placard_data      = @target ? @target.placard_data : @placard.placard_data
    @parent_collection = parent_collection_for(@target)
    @preview_photo     = (@target || @placard)&.placard_photo
    @show_item_nav     = @target.respond_to?(:prev_item) && @target.respond_to?(:next_item)
    @prev_item         = @show_item_nav ? @target.prev_item : nil
    @next_item         = @show_item_nav ? @target.next_item : nil
  end

  # GET /placard/:id/display or GET /placard/display?target_type=...&target_id=...
  # Displays print-proportioned WYSIWYG MD card of the physical wall placard
  def display
    return unless @target || @placard

    @placard_data      = @target ? @target.placard_data : @placard.placard_data
    @parent_collection = parent_collection_for(@target)
    @display_mode      = helpers.normalize_placard_display_mode(params[:mode])
    @paper_size        = helpers.normalize_placard_paper_size(params[:size])
  end

  # GET /placard/new?target_type=...&target_id=...
  def new
    @target = find_target(params[:target_type], params[:target_id])
    @placard = Placard.new
    @upstream_data = upstream_placard_data_for(@target)
  end

  # POST /placard
  def create
    @target = find_target(params[:target_type], params[:target_id])
    @placard = Placard.new(placard_params)

    if @placard.save
      @target.update!(placard: @placard) if @target
      redirect_to post_save_redirect_path(@placard, @target), notice: "Placard created successfully."
    else
      @upstream_data = upstream_placard_data_for(@target)
      render :new, status: :unprocessable_entity
    end
  end

  # GET /placard/:id/edit
  def edit
    @target = find_target(params[:target_type], params[:target_id]) || inferred_owner_for(@placard)
    @upstream_data = upstream_placard_data_for(@target)
  end

  # PATCH/PUT /placard/:id
  def update
    @target = find_target(params[:target_type], params[:target_id]) || inferred_owner_for(@placard)

    if @placard.update(placard_params)
      redirect_to post_save_redirect_path(@placard, @target), notice: "Placard updated successfully."
    else
      @upstream_data = upstream_placard_data_for(@target)
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /placard/:id
  def destroy
    owner = find_target(params[:target_type], params[:target_id]) || inferred_owner_for(@placard)
    @placard.destroy!

    if owner
      redirect_to itemcard_placard_index_path(target_type: owner.class.name, target_id: owner.id),
                  notice: "Placard override removed; reverted to inherited values."
    else
      redirect_to placard_index_path, notice: "Placard removed."
    end
  end

  private

  def set_placard
    @placard = Placard.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to placard_index_path, alert: "Placard not found."
  end

  def resolve_context
    @target  = find_target(params[:target_type], params[:target_id])
    @placard = if params[:id].present?
                 Placard.find_by(id: params[:id])
               else
                 @target&.placard
               end

    if @target.nil? && @placard.nil?
      redirect_to placard_index_path, alert: "Placard or target record not found."
    end
  end

  def resolve_collection_from_context!
    if @target.is_a?(Portfolio) || @target.is_a?(Exhibition)
      return @target
    end

    if @placard
      owner = @placard.portfolios.first || @placard.exhibitions.first
      return owner if owner
    end

    redirect_to placard_index_path, alert: "Collection not found for placard."
    nil
  end

  def find_target(target_type, target_id)
    return nil unless ALLOWED_TARGET_TYPES.include?(target_type.to_s) && target_id.present?

    target_type.to_s.constantize.find_by(id: target_id)
  end

  def inferred_owner_for(placard)
    return nil unless placard

    placard.exhibition_items.first ||
      placard.portfolio_items.first ||
      placard.exhibitions.first ||
      placard.portfolios.first
  end

  def parent_collection_for(target)
    case target
    when Portfolio, Exhibition then target
    when PortfolioItem         then target.portfolio
    when ExhibitionItem        then target.exhibition
    else nil
    end
  end

  def upstream_placard_data_for(target)
    case target
    when Portfolio
      Portfolio.default_placard_data(target)
    when Exhibition
      target.portfolio ? target.portfolio.placard_data : Exhibition.default_placard_data(target)
    when PortfolioItem
      col_pd = target.portfolio ? target.portfolio.placard_data : ::Gallery::Environ::PlacardData.new
      target.photo ? target.photo.placard_data(col_pd) : col_pd
    when ExhibitionItem
      col_pd = target.exhibition ? target.exhibition.placard_data : ::Gallery::Environ::PlacardData.new
      item_pd = target.photo ? target.photo.placard_data(col_pd) : col_pd
      source_pi = if target.exhibition&.portfolio_id
                    PortfolioItem.find_by(portfolio_id: target.exhibition.portfolio_id, photo_id: target.photo_id)
                  else
                    PortfolioItem.find_by(photo_id: target.photo_id)
                  end
      if source_pi&.placard
        pi_attrs = source_pi.placard.placard_attributes.slice(*::Gallery::Environ::PlacardData::ITEM_FIELDS)
        item_pd = item_pd.merge(source_pi, pi_attrs, status: :cascaded) if pi_attrs.any?
      end
      item_pd
    else
      ::Gallery::Environ::PlacardData.new
    end
  end

  def post_save_redirect_path(placard, target)
    if target
      itemcard_placard_index_path(target_type: target.class.name, target_id: target.id)
    else
      itemcard_placard_path(placard)
    end
  end

  def placard_params
    permitted = params.require(:placard).permit(
      :title,
      :subtitle,
      :curatorial_notes,
      :artist_name,
      :subject,
      :date_created_display,
      :location_display,
      :medium,
      :dimensions_display,
      :edition_info,
      :price,
      :sales_notes,
      :cc_license,
      :copyright_year,
      :copyright_holder
    )
    # Normalize blank strings to nil so unset fields cascade rather than shadowing ancestors
    permitted.transform_values { |v| v.is_a?(String) && v.strip.empty? ? nil : v }
  end
end  # class

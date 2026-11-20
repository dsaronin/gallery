class PhotoController < ApplicationController
  CollectionSpec = Data.define(:kind, :plural, :model_class, :join_assoc, :foreign_key, :param_key, :state_setter)

  COLLECTION_SPECS = {
    portfolio: CollectionSpec.new(
      kind:         :portfolio,
      plural:       "portfolios",
      model_class:  Portfolio,
      join_assoc:   :portfolio_items,
      foreign_key:  :portfolio_id,
      param_key:    :portfolio_id,
      state_setter: :current_portfolio_id=
    ),
    exhibition: CollectionSpec.new(
      kind:         :exhibition,
      plural:       "exhibitions",
      model_class:  Exhibition,
      join_assoc:   :exhibition_items,
      foreign_key:  :exhibition_id,
      param_key:    :exhibition_id,
      state_setter: :current_exhibition_id=
    )
  }.freeze

  before_action :validate_photo, only: %i[
    show update assign_tag remove_tag
    assign_portfolio remove_portfolio assign_exhibition remove_exhibition
  ]
 
  def show
    @assigned_tags = @photo.tags.includes(:category).order("categories.name, tags.name")
    @categories    = Category.includes(:tags).order(:name)
    @available_tags = Tag.where.not(id: @photo.tag_ids).order(:name)
  end

  def update
    if @photo.update(photo_params)
      respond_to do |format|
        format.turbo_stream
        format.html do
          if turbo_frame_request?
            render partial: "photo/star_rating", locals: { photo: @photo }
          else
            redirect_back fallback_location: catalog_path(@photo.catalog)
          end
        end
      end
    else
      head :unprocessable_entity
    end
  end

  def assign_tag
    tag = Tag.find(params[:tag_id])
    @photo.tags << tag unless @photo.tags.include?(tag)
    gallery_state.set_active_tag!(tag)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to photo_path(@photo) }
    end
  end

  def remove_tag
    tag = Tag.find(params[:tag_id])
    @photo.tags.destroy(tag)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to photo_path(@photo) }
    end
  end

  def assign_portfolio
    assign_collection_item(COLLECTION_SPECS[:portfolio])
  end

  def remove_portfolio
    remove_collection_item(COLLECTION_SPECS[:portfolio])
  end

  def assign_exhibition
    assign_collection_item(COLLECTION_SPECS[:exhibition])
  end

  def remove_exhibition
    remove_collection_item(COLLECTION_SPECS[:exhibition])
  end

  private

  def assign_collection_item(spec)
    record = spec.model_class.find_by(id: params[spec.param_key])
    if record
      items = @photo.public_send(spec.join_assoc)
      items.create!(spec.foreign_key => record.id) unless items.exists?(spec.foreign_key => record.id)
      gallery_state.public_send(spec.state_setter, record.id)
    end

    respond_to_collection_mutation(spec)
  end

  def remove_collection_item(spec)
    item = @photo.public_send(spec.join_assoc).find_by(spec.foreign_key => params[spec.param_key])
    item&.destroy

    respond_to_collection_mutation(spec)
  end

  def respond_to_collection_mutation(spec)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "photo_#{spec.plural}_#{@photo.id}",
          partial: "photo/collection_memberships",
          locals: { photo: @photo, kind: spec.kind }
        )
      end
      format.html { redirect_to photo_path(@photo) }
    end
  end

  def photo_params
    params.require(:photo).permit(:stars, :photo_dsc, :notes, :talent_id)
  end

# ------------------------------------------------------------------------------
  def validate_photo()
    @photo = Photo.find(params[:id])
    true     # returning true continues controller action
    
  rescue ActiveRecord::RecordNotFound
    puts "SHOW: ERROR NOT FOUND"
      flash[:notice] = "photo not found"
      flash[:show_flash] = true
      redirect_back fallback_location: root_path
      false
  end

# ------------------------------------------------------------------------------

end   # controller

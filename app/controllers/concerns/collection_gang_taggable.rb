# frozen_string_literal: true

# -----------------------------------------------------------------------------
# GALLERY: CollectionGangTaggable Concern
# File: app/controllers/concerns/collection_gang_taggable.rb
#
# PURPOSE:
# Shared POST :assign_tag action for CatalogController, PortfolioController,
# and ExhibitionController. Gang-assigns a Category::Tag across all member
# photos in the target collection and updates sticky session state.
# -----------------------------------------------------------------------------

module CollectionGangTaggable
  extend ActiveSupport::Concern

  # POST /<collection>/:id/assign_tag
  def assign_tag
    collection = gang_tag_collection
    tag        = resolve_gang_tag

    unless tag
      redirect_to collection, alert: "Select a valid tag to assign."
      return
    end

    result = collection.gang_assign_tag!(tag)
    gallery_state.set_active_tag!(tag)

    redirect_to collection, notice: format_gang_tag_notice(result)
  end

  private

  def gang_tag_collection
    instance_variable_get("@#{controller_name}")
  end

  def resolve_gang_tag
    return nil if params[:tag_id].blank?

    Tag.includes(:category).find_by(id: params[:tag_id])
  end

  def format_gang_tag_notice(result)
    label = "#{result.tag.category.name}::#{result.tag.name}"
    if result.total_count.zero?
      "No photos in collection for tagging: #{label}."
    else
      "Tagged #{label} across #{result.total_count} #{'photo'.pluralize(result.total_count)} (#{result.added_count} added, #{result.skipped_count} already tagged)."
    end
  end
end

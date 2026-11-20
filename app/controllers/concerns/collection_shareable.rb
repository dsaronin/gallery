# frozen_string_literal: true

# -----------------------------------------------------------------------------
# GALLERY: CollectionShareable Concern
# File: app/controllers/concerns/collection_shareable.rb
#
# PURPOSE:
# Shared PATCH :make_public and :make_private actions for PortfolioController
# and ExhibitionController. Toggles public share_token state and redirects back
# to the collection index view.
# -----------------------------------------------------------------------------

module CollectionShareable
  extend ActiveSupport::Concern

# *********************************************
  # PATCH /<collection>/:id/make_public
  def make_public
    collection = shareable_collection
    collection.make_public!

    redirect_to shareable_index_path, notice: "#{shareable_label(collection)} is now public."
  end

  # PATCH /<collection>/:id/make_private
  def make_private
    collection = shareable_collection
    collection.make_private!

    redirect_to shareable_index_path, notice: "#{shareable_label(collection)} is now private."
  end
# *********************************************

  private

# *********************************************
  def shareable_collection
    instance_variable_get("@#{controller_name}")
  end

  def shareable_index_path
    public_send("#{controller_name}_index_path")
  end

  def shareable_label(collection)
    "#{collection.class.model_name.human} \"#{collection.title}\""
  end

# *********************************************
end  # module

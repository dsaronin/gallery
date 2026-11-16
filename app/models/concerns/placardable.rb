# frozen_string_literal: true

# Gallery:
# Copyright (c) 2026 David S Anderson, All Rights Reserved
#
# Concern: Placardable
# Provides the unified `#placard_data(preceding_data = nil)` pipeline method
# across Photo, Portfolio, PortfolioItem, Exhibition, ExhibitionItem, and Placard.

module Placardable
  extend ActiveSupport::Concern

  # Accepts an optional upstream PlacardData instance, overlays this object's
  # partition-filtered placard attributes, and returns a new merged PlacardData.
  #
  # @param preceding_data [Gallery::Environ::PlacardData, nil]
  # @return [Gallery::Environ::PlacardData]
  def placard_data(preceding_data = nil, provenance_source: nil)
    base = preceding_data || ::Gallery::Environ::PlacardData.new
    base.merge(self, placard_attributes, status: placard_provenance_status, provenance_source: provenance_source)
  end

  # Override in including models to supply the raw hash of placard attributes.
  def placard_attributes
    {}
  end

  # Override in including models when provenance status differs from :direct
  # (e.g., :intrinsic for Photo, :default for unpersisted Collection fallbacks).
  def placard_provenance_status
    :direct
  end

  # Resolves the representative Photo for any Placardable model:
  # - Collection (Portfolio / Exhibition): first curated item's photo
  # - Item (PortfolioItem / ExhibitionItem): self.photo
  # - Photo: self
  # - Placard: delegates to its primary attached owner
  def placard_photo
    if is_a?(Photo)
      self
    elsif respond_to?(:items_association)
      items_association.first&.photo
    elsif respond_to?(:photo)
      photo
    elsif is_a?(Placard)
      owner = exhibition_items.first || portfolio_items.first || exhibitions.first || portfolios.first
      owner&.placard_photo
    end
  end

# ***********************************
end   # module


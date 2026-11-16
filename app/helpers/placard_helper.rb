# frozen_string_literal: true

# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2026 David S Anderson, All Rights Reserved
# ----------------------------------------------------------

# app/helpers/placard_helper.rb
module PlacardHelper
  # Returns CSS class distinguishing :direct vs :cascaded/:intrinsic/:default values
  def placard_provenance_class(placard_data, field)
    return "placard-val-empty" unless placard_data&.present_field?(field)

    if placard_data.direct?(field)
      "placard-val-direct"
    else
      "placard-val-cascaded"
    end
  end

  # Returns concise human-readable provenance description for hover tooltips
  # Returns concise human-readable provenance label for hover tooltips
  def placard_provenance_tooltip(placard_data, field)
    meta = placard_data&.provenance_for(field)
    return nil unless meta && placard_data.present_field?(field)

    meta[:status] == :direct ? "Direct" : placard_data.source_label_for(field)
  end

  # Builds path to Placard#show for a Portfolio or Exhibition
  def collection_placard_show_path(collection)
    if collection.placard_id.present?
      placard_path(collection.placard_id, target_type: collection.class.name, target_id: collection.id)
    else
      collection_show_placard_index_path(target_type: collection.class.name, target_id: collection.id)
    end
  end

  # Builds path to Placard#itemcard for any target or Placard
  def target_placard_itemcard_path(target, placard = nil)
    if target
      itemcard_placard_index_path(target_type: target.class.name, target_id: target.id)
    elsif placard
      itemcard_placard_path(placard)
    else
      placard_index_path
    end
  end

  # Builds path to Placard#display for any target or Placard
  def target_placard_display_path(target, placard = nil)
    if target
      display_placard_index_path(target_type: target.class.name, target_id: target.id)
    elsif placard
      display_placard_path(placard)
    else
      placard_index_path
    end
  end

  # Formats integer price as currency string or returns nil
  def format_placard_price(price)
    return nil if price.nil?
    return "Not for Sale" if price.zero?

    "$#{number_with_delimiter(price)}"
  end

  def normalize_placard_display_mode(raw)
    sym = raw.to_s.downcase.to_sym
    if ::Gallery::Environ::PLACARD_DISPLAY_MODES.key?(sym)
      sym.to_s
    else
      ::Gallery::Environ::DEFAULT_PLACARD_DISPLAY_MODE.to_s
    end
  end

  def normalize_placard_paper_size(raw)
    sym = raw.to_s.downcase.to_sym
    if ::Gallery::Environ::PLACARD_PAPER_SIZES.key?(sym)
      sym.to_s
    else
      ::Gallery::Environ::DEFAULT_PLACARD_PAPER_SIZE.to_s
    end
  end

  # Builds path to Placard#display preserving mode and paper size params
  def placard_display_variant_path(target, placard, mode:, size:)
    if target
      display_placard_index_path(target_type: target.class.name, target_id: target.id, mode: mode, size: size)
    elsif placard
      display_placard_path(placard, mode: mode, size: size)
    else
      placard_index_path
    end
  end

# ****************************************************
end   # class

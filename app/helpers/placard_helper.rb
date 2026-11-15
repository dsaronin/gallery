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

  # Returns concise human-readable provenance badge label for administrative display
  def placard_provenance_badge(placard_data, field)
    meta = placard_data&.provenance_for(field)
    return nil unless meta && placard_data.present_field?(field)

    case meta[:status]
    when :direct    then "Direct"
    when :intrinsic then "Photo"
    when :default   then "Default"
    when :cascaded  then "Cascaded (#{meta[:source_class]})"
    end
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
end   # class

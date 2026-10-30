module PhotoHelper
  GLYPH_REJECT_INACTIVE = "\u25C7" # White Diamond (◇)
  GLYPH_REJECT_ACTIVE   = "\u25C6" # Black Diamond (◆)

  def reject_glyph_for(photo)
    photo.rejected? ? GLYPH_REJECT_ACTIVE : GLYPH_REJECT_INACTIVE
  end

  def reject_button_class(photo)
    photo.rejected? ? 'reject-btn active' : 'reject-btn'
  end

  # render_star_bar -- prepares the star rating bar for output
  #
  def render_star_bar(photo)
    content_tag(:div, class: "star-bar") do
      # Reject button: -1 (toggles to 0 if already -1)
      reject_target = photo.rejected? ? 0 : -1
      reject_btn = star_button(photo, reject_target, reject_glyph_for(photo), reject_button_class(photo))

      # 1..5 Star buttons (toggles to 0 if clicking current score)
      star_btns = (1..5).map do |i|
        target = (photo.stars == i) ? 0 : i
        is_active = photo.stars >= i
        star_char = is_active ? "★" : "☆"
        star_btn_class = is_active ? "star-btn active" : "star-btn"
        star_button(photo, target, star_char, star_btn_class)
      end

      safe_join([reject_btn, *star_btns])
    end
  end

  private

  def star_button(photo, target_val, glyph, css_class)
    button_to(
      glyph,
      photo_path(photo, photo: { stars: target_val }),
      method: :patch,
      class: css_class,
      form_class: "star-form",
      data: { turbo_frame: dom_id(photo, :stars) }
    )
  end

end   # module PhotoHelper

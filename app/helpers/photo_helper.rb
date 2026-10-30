module PhotoHelper

  # render_star_bar -- prepares the star rating bar for output
  #
  def render_star_bar(photo)
    content_tag(:div, class: "star-bar") do
      # Reject button: -1 (toggles to 0 if already -1)
      reject_target = photo.rejected? ? 0 : -1
      reject_btn = star_button(photo, reject_target, "✕", photo.rejected? ? "btn-reject active" : "btn-reject")

      # 1..5 Star buttons (toggles to 0 if clicking current score)
      star_btns = (1..5).map do |i|
        target = (photo.stars == i) ? 0 : i
        is_active = photo.stars >= i
        star_char = is_active ? "★" : "☆"
        star_button(photo, target, star_char, is_active ? "btn-star active" : "btn-star")
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
      class: "star-action #{css_class}",
      form_class: "star-form",
      data: { turbo_frame: dom_id(photo, :stars) }
    )
  end

end   # module PhotoHelper

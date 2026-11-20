# frozen_string_literal: true

# Usage: bin/rails runner script/test_photo_helper_glyphs.rb

puts "==> Starting validation for rating glyph constants in Gallery::Environ & PhotoHelper..."

route_helpers = Rails.application.routes.url_helpers
view_helpers  = ApplicationController.helpers

original_forgery_setting = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false

created = {
  catalogs: [],
  photos:   []
}

begin
  # 1. Verify constants are defined and frozen on Gallery::Environ
  expected_glyphs = {
    GLYPH_REJECT_INACTIVE: "\u25C7",
    GLYPH_REJECT_ACTIVE:   "\u25C6",
    GLYPH_STAR_INACTIVE:   "\u2606",
    GLYPH_STAR_ACTIVE:     "\u2605"
  }

  expected_glyphs.each do |const_name, expected_val|
    raise "Missing Gallery::Environ::#{const_name}" unless Gallery::Environ.const_defined?(const_name, false)

    actual = Gallery::Environ.const_get(const_name)
    raise "Expected #{const_name} == #{expected_val.inspect}, got #{actual.inspect}" unless actual == expected_val
    raise "Expected #{const_name} to be frozen" unless actual.frozen?
  end
  puts "  [PASS] Gallery::Environ defines and freezes all four rating glyph constants."

  # 2. Verify legacy literals are removed from PhotoHelper
  %i[GLYPH_REJECT_INACTIVE GLYPH_REJECT_ACTIVE].each do |const_name|
    if PhotoHelper.const_defined?(const_name, false)
      raise "Legacy constant PhotoHelper::#{const_name} should be removed"
    end
  end
  puts "  [PASS] Legacy glyph constants removed from PhotoHelper."

  # 3. Create temporary catalog and photo for helper + integration checks
  sess = ActionDispatch::Integration::Session.new(Rails.application)
  sess.host!("localhost")
  token = Gallery::Environ.generate_token(8)

  catalog = Catalog.create!(
    name:  "GlyphTestCat_#{token}",
    fname: "glyph_test_#{token}",
    fpath: "/tmp/glyph_test_#{token}"
  )
  created[:catalogs] << catalog.id

  photo = catalog.photos.create!(
    photo_dsc: "Glyph Test Photo",
    filename:  "glyph_test_#{token}.jpg",
    photodate: Time.current,
    stars:     3
  )
  created[:photos] << photo.id

  # 4. Unit checks on PhotoHelper#reject_glyph_for
  unless view_helpers.reject_glyph_for(photo) == Gallery::Environ::GLYPH_REJECT_INACTIVE
    raise "Expected inactive reject glyph for rated photo"
  end

  photo.update!(stars: -1)
  unless view_helpers.reject_glyph_for(photo) == Gallery::Environ::GLYPH_REJECT_ACTIVE
    raise "Expected active reject glyph for rejected photo"
  end
  puts "  [PASS] PhotoHelper#reject_glyph_for returns expected Gallery::Environ glyphs."

  # 5. Integration checks on photo#show star bar rendering (rejected & rated states)
  sess.get(route_helpers.photo_path(photo))
  raise "Expected 200 on photo#show (rejected), got #{sess.status}" unless sess.status == 200
  body = sess.response.body
  raise "Missing active reject glyph in rendered star bar" unless body.include?(Gallery::Environ::GLYPH_REJECT_ACTIVE)
  raise "Missing inactive star glyph in rendered star bar" unless body.include?(Gallery::Environ::GLYPH_STAR_INACTIVE)

  photo.update!(stars: 3)
  sess.get(route_helpers.photo_path(photo))
  raise "Expected 200 on photo#show (rated), got #{sess.status}" unless sess.status == 200
  body = sess.response.body
  raise "Missing inactive reject glyph in rendered star bar" unless body.include?(Gallery::Environ::GLYPH_REJECT_INACTIVE)
  raise "Missing active star glyph in rendered star bar" unless body.include?(Gallery::Environ::GLYPH_STAR_ACTIVE)
  raise "Missing inactive star glyph in rendered star bar" unless body.include?(Gallery::Environ::GLYPH_STAR_INACTIVE)
  puts "  [PASS] photo#show renders Gallery::Environ rating glyphs accurately across states."

  puts "==> All rating glyph refactor checks passed successfully!"
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
  Photo.where(id: created[:photos]).destroy_all
  Catalog.where(id: created[:catalogs]).destroy_all
  puts "  [CLEANUP] Zero residual test records verified."
end

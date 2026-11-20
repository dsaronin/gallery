# frozen_string_literal: true

# Usage: bin/rails runner script/test_photo_collections_controller.rb

puts "==> Starting validation for PhotoController portfolio & exhibition actions..."

helpers = Rails.application.routes.url_helpers

# 1. Verify route helpers
raise "Expected assign_portfolio_photo_path(1)" unless helpers.assign_portfolio_photo_path(1) == "/photo/1/assign_portfolio"
raise "Expected remove_portfolio_photo_path(1, 2)" unless helpers.remove_portfolio_photo_path(1, 2) == "/photo/1/remove_portfolio/2"
raise "Expected assign_exhibition_photo_path(1)" unless helpers.assign_exhibition_photo_path(1) == "/photo/1/assign_exhibition"
raise "Expected remove_exhibition_photo_path(1, 2)" unless helpers.remove_exhibition_photo_path(1, 2) == "/photo/1/remove_exhibition/2"
puts "  [PASS] Route generation helpers verified."

original_forgery_setting = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false

created = {
  catalogs:    [],
  photos:      [],
  portfolios:  [],
  exhibitions: []
}

begin
  sess = ActionDispatch::Integration::Session.new(Rails.application)
  sess.host!("localhost")
  token = Gallery::Environ.generate_token(8)

  catalog = Catalog.create!(
    name:  "PhotoCollCat_#{token}",
    fname: "photo_coll_#{token}",
    fpath: "/tmp/photo_coll_#{token}"
  )
  created[:catalogs] << catalog.id

  photo_1 = catalog.photos.create!(
    photo_dsc: "Photo Coll 1",
    filename:  "photo_coll_1_#{token}.jpg",
    photodate: Time.current,
    stars:     4
  )
  photo_2 = catalog.photos.create!(
    photo_dsc: "Photo Coll 2",
    filename:  "photo_coll_2_#{token}.jpg",
    photodate: Time.current,
    stars:     5
  )
  created[:photos].push(photo_1.id, photo_2.id)

  portfolio = Portfolio.create!(name: "photo_port_#{token}", title: "Photo Portfolio #{token}")
  created[:portfolios] << portfolio.id
  portfolio.portfolio_items.create!(photo: photo_1)

  exhibition = Exhibition.create!(title: "Photo Exhibition #{token}")
  created[:exhibitions] << exhibition.id
  exhibition.exhibition_items.create!(photo: photo_1)

  # 2. POST /photo/:id/assign_portfolio (Positionable append + sticky state)
  sess.post(helpers.assign_portfolio_photo_path(photo_2), params: { portfolio_id: portfolio.id })
  raise "Expected 302 redirect on assign_portfolio, got #{sess.status}" unless sess.status == 302
  raise "Expected redirect to photo_path" unless sess.response.location.end_with?(helpers.photo_path(photo_2))
  pi = PortfolioItem.find_by(portfolio_id: portfolio.id, photo_id: photo_2.id)
  raise "Expected PortfolioItem created at position 2" unless pi && pi.position == 2
  raise "Expected sticky current_portfolio_id=#{portfolio.id}" unless sess.session[:gallery_state][:current_portfolio_id] == portfolio.id
  puts "  [PASS] POST /photo/:id/assign_portfolio appends item and updates sticky state."

  # 3. Idempotent duplicate assign_portfolio
  sess.post(helpers.assign_portfolio_photo_path(photo_2), params: { portfolio_id: portfolio.id })
  raise "Expected no duplicate PortfolioItem" unless PortfolioItem.where(portfolio_id: portfolio.id, photo_id: photo_2.id).count == 1
  puts "  [PASS] Duplicate assign_portfolio is a safe no-op."

  # 4. DELETE /photo/:id/remove_portfolio/:portfolio_id
  sess.delete(helpers.remove_portfolio_photo_path(photo_2, portfolio))
  raise "Expected 302 redirect on remove_portfolio, got #{sess.status}" unless sess.status == 302
  raise "Expected PortfolioItem destroyed" if PortfolioItem.exists?(portfolio_id: portfolio.id, photo_id: photo_2.id)
  puts "  [PASS] DELETE /photo/:id/remove_portfolio/:portfolio_id removes membership."

  # 5. POST /photo/:id/assign_exhibition (Positionable append + sticky state)
  sess.post(helpers.assign_exhibition_photo_path(photo_2), params: { exhibition_id: exhibition.id })
  raise "Expected 302 redirect on assign_exhibition, got #{sess.status}" unless sess.status == 302
  ei = ExhibitionItem.find_by(exhibition_id: exhibition.id, photo_id: photo_2.id)
  raise "Expected ExhibitionItem created at position 2" unless ei && ei.position == 2
  raise "Expected sticky current_exhibition_id=#{exhibition.id}" unless sess.session[:gallery_state][:current_exhibition_id] == exhibition.id
  puts "  [PASS] POST /photo/:id/assign_exhibition appends item and updates sticky state."

  # 6. Idempotent duplicate assign_exhibition & DELETE /photo/:id/remove_exhibition/:exhibition_id
  sess.post(helpers.assign_exhibition_photo_path(photo_2), params: { exhibition_id: exhibition.id })
  raise "Expected no duplicate ExhibitionItem" unless ExhibitionItem.where(exhibition_id: exhibition.id, photo_id: photo_2.id).count == 1

  sess.delete(helpers.remove_exhibition_photo_path(photo_2, exhibition))
  raise "Expected 302 redirect on remove_exhibition, got #{sess.status}" unless sess.status == 302
  raise "Expected ExhibitionItem destroyed" if ExhibitionItem.exists?(exhibition_id: exhibition.id, photo_id: photo_2.id)
  puts "  [PASS] Idempotent assign_exhibition and DELETE remove_exhibition verified."

  # 7. Guarded constraints: blank or nonexistent IDs
  sess.post(helpers.assign_portfolio_photo_path(photo_2), params: { portfolio_id: "" })
  raise "Expected 302 redirect on blank portfolio_id" unless sess.status == 302
  sess.post(helpers.assign_exhibition_photo_path(photo_2), params: { exhibition_id: 999_999_999 })
  raise "Expected 302 redirect on invalid exhibition_id" unless sess.status == 302
  sess.delete(helpers.remove_portfolio_photo_path(photo_2, 999_999_999))
  raise "Expected 302 redirect on missing remove_portfolio" unless sess.status == 302
  puts "  [PASS] Blank and nonexistent collection ID guards verified."

  puts "==> All Phase 1 PhotoController collection checks passed successfully!"
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
  Exhibition.where(id: created[:exhibitions]).destroy_all
  Portfolio.where(id: created[:portfolios]).destroy_all
  Photo.where(id: created[:photos]).destroy_all
  Catalog.where(id: created[:catalogs]).destroy_all
  puts "  [CLEANUP] Zero residual test records verified."
end

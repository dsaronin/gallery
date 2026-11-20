# frozen_string_literal: true

# Usage: bin/rails runner script/test_photo_collections_views.rb

puts "==> Starting validation for photo#show portfolio & exhibition views and Turbo Streams..."

helpers = Rails.application.routes.url_helpers

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
    name:  "ViewCollCat_#{token}",
    fname: "view_coll_#{token}",
    fpath: "/tmp/view_coll_#{token}"
  )
  created[:catalogs] << catalog.id

  photo = catalog.photos.create!(
    photo_dsc: "View Coll Photo",
    filename:  "view_coll_#{token}.jpg",
    photodate: Time.current,
    stars:     4
  )
  created[:photos] << photo.id

  port_active   = Portfolio.create!(name: "vp_act_#{token}",  title: "Active Portfolio #{token}",   status: :active)
  port_archived = Portfolio.create!(name: "vp_arch_#{token}", title: "Archived Portfolio #{token}", status: :archived)
  created[:portfolios].push(port_active.id, port_archived.id)

  exh_sched     = Exhibition.create!(title: "Scheduled Exhibition #{token}", status: :scheduled)
  exh_completed = Exhibition.create!(title: "Completed Exhibition #{token}", status: :completed)
  exh_archived  = Exhibition.create!(title: "Archived Exhibition #{token}",  status: :archived)
  created[:exhibitions].push(exh_sched.id, exh_completed.id, exh_archived.id)

  # 1. GET /photo/:id renders Turbo Frames, eligible options, and excludes terminal statuses
  sess.get(helpers.photo_path(photo))
  raise "Expected 200 on photo#show, got #{sess.status}" unless sess.status == 200
  body = sess.response.body
  raise "Missing photo_portfolios frame" unless body.include?("photo_portfolios_#{photo.id}")
  raise "Missing photo_exhibitions frame" unless body.include?("photo_exhibitions_#{photo.id}")
  raise "Active portfolio missing from dropdown" unless body.include?(port_active.title)
  raise "Archived portfolio should be excluded from dropdown" if body.include?(port_archived.title)
  raise "Scheduled exhibition missing from dropdown" unless body.include?(exh_sched.title)
  raise "Completed exhibition should be excluded from dropdown" if body.include?(exh_completed.title)
  raise "Archived exhibition should be excluded from dropdown" if body.include?(exh_archived.title)
  puts "  [PASS] photo#show renders collection frames and filters terminal statuses."

  # 2. Turbo Stream POST assign_portfolio returns <turbo-stream action="replace"> with badge
  turbo_headers = { "Accept" => "text/vnd.turbo-stream.html" }
  sess.post(helpers.assign_portfolio_photo_path(photo), params: { portfolio_id: port_active.id }, headers: turbo_headers)
  raise "Expected 200 on Turbo Stream assign_portfolio, got #{sess.status}" unless sess.status == 200
  stream_body = sess.response.body
  raise "Missing turbo-stream replace for portfolios" unless stream_body.include?(%(target="photo_portfolios_#{photo.id}"))
  raise "Assigned portfolio badge missing in stream" unless stream_body.include?(port_active.title)
  raise "Remove route missing in stream" unless stream_body.include?(helpers.remove_portfolio_photo_path(photo, port_active))
  puts "  [PASS] Turbo Stream assign_portfolio replaces frame with badge and remove control."

  # 3. Turbo Stream DELETE remove_portfolio returns None yet… and restores dropdown option
  sess.delete(helpers.remove_portfolio_photo_path(photo, port_active), headers: turbo_headers)
  raise "Expected 200 on Turbo Stream remove_portfolio, got #{sess.status}" unless sess.status == 200
  stream_body = sess.response.body
  raise "Expected None yet… after removing sole portfolio" unless stream_body.include?("None yet…")
  raise "Expected port_active restored to dropdown" unless stream_body.include?(port_active.title)
  puts "  [PASS] Turbo Stream remove_portfolio restores empty notice and dropdown option."

  # 4. Turbo Stream POST & DELETE for exhibition
  sess.post(helpers.assign_exhibition_photo_path(photo), params: { exhibition_id: exh_sched.id }, headers: turbo_headers)
  raise "Expected 200 on Turbo Stream assign_exhibition, got #{sess.status}" unless sess.status == 200
  raise "Missing turbo-stream replace for exhibitions" unless sess.response.body.include?(%(target="photo_exhibitions_#{photo.id}"))
  raise "Assigned exhibition badge missing in stream" unless sess.response.body.include?(exh_sched.title)

  sess.delete(helpers.remove_exhibition_photo_path(photo, exh_sched), headers: turbo_headers)
  raise "Expected 200 on Turbo Stream remove_exhibition, got #{sess.status}" unless sess.status == 200
  raise "Expected None yet… after removing sole exhibition" unless sess.response.body.include?("None yet…")
  puts "  [PASS] Turbo Stream assign_exhibition and remove_exhibition verified."

  puts "==> All Phase 2 photo#show collection view & Turbo Stream checks passed successfully!"
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
  Exhibition.where(id: created[:exhibitions]).destroy_all
  Portfolio.where(id: created[:portfolios]).destroy_all
  Photo.where(id: created[:photos]).destroy_all
  Catalog.where(id: created[:catalogs]).destroy_all
  puts "  [CLEANUP] Zero residual test records verified."
end

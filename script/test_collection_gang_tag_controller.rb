# frozen_string_literal: true

# Usage: bin/rails runner script/test_collection_gang_tag_controller.rb

puts "==> Starting validation for CollectionGangTaggable controller routes & actions..."

helpers = Rails.application.routes.url_helpers

# 1. Verify route generation helpers across all three collection types
raise "Expected assign_tag_catalog_path(1) to be /catalog/1/assign_tag" unless helpers.assign_tag_catalog_path(1) == "/catalog/1/assign_tag"
raise "Expected assign_tag_portfolio_path(1) to be /portfolio/1/assign_tag" unless helpers.assign_tag_portfolio_path(1) == "/portfolio/1/assign_tag"
raise "Expected assign_tag_exhibition_path(1) to be /exhibition/1/assign_tag" unless helpers.assign_tag_exhibition_path(1) == "/exhibition/1/assign_tag"
puts "  [PASS] Route helpers verified for catalog, portfolio, and exhibition."

original_forgery_setting = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false

created = {
  categories:  [],
  tags:        [],
  catalogs:    [],
  photos:      [],
  portfolios:  [],
  exhibitions: []
}

begin
  sess = ActionDispatch::Integration::Session.new(Rails.application)
  sess.host!("localhost")
  token = Gallery::Environ.generate_token(8)

  cat = Category.create!(name: "CtrlCat_#{token}")
  created[:categories] << cat.id

  tag_cat = Tag.create!(name: "CatTag_#{token}", category: cat)
  tag_prt = Tag.create!(name: "PrtTag_#{token}", category: cat)
  tag_exh = Tag.create!(name: "ExhTag_#{token}", category: cat)
  created[:tags].push(tag_cat.id, tag_prt.id, tag_exh.id)

  catalog = Catalog.create!(
    name:  "CtrlCatalog_#{token}",
    fname: "ctrl_gang_#{token}",
    fpath: "/tmp/ctrl_gang_#{token}"
  )
  created[:catalogs] << catalog.id

  photos = 2.times.map do |i|
    p = catalog.photos.create!(
      photo_dsc: "Ctrl Gang Photo #{i + 1}",
      filename:  "ctrl_gang_#{token}_#{i + 1}.jpg",
      photodate: Time.current,
      stars:     4
    )
    created[:photos] << p.id
    p
  end

  # Pre-tag photo[0] with tag_cat to verify union OR count reporting
  photos[0].tags << tag_cat

  # 2. POST /catalog/:id/assign_tag
  sess.post(helpers.assign_tag_catalog_path(catalog), params: { tag_id: tag_cat.id })
  raise "Expected 302 redirect on catalog assign_tag, got #{sess.status}" unless sess.status == 302
  raise "Expected redirect to catalog_path" unless sess.response.location.end_with?(helpers.catalog_path(catalog))
  raise "Expected notice with counts" unless sess.flash[:notice].to_s.include?("1 added, 1 already tagged")
  raise "Expected sticky current_tag_id=#{tag_cat.id}" unless sess.session[:gallery_state][:current_tag_id] == tag_cat.id
  raise "Expected sticky current_category_id=#{cat.id}" unless sess.session[:gallery_state][:current_category_id] == cat.id
  raise "Expected all catalog photos tagged" unless photos.all? { |p| p.reload.tag_ids.include?(tag_cat.id) }
  puts "  [PASS] POST /catalog/:id/assign_tag and sticky session state verified."

  # 3. POST /portfolio/:id/assign_tag
  portfolio = Portfolio.create!(name: "ctrl_port_#{token}", title: "Ctrl Portfolio #{token}")
  created[:portfolios] << portfolio.id
  portfolio.portfolio_items.create!(photo: photos[0], position: 1)

  sess.post(helpers.assign_tag_portfolio_path(portfolio), params: { tag_id: tag_prt.id })
  raise "Expected 302 redirect on portfolio assign_tag, got #{sess.status}" unless sess.status == 302
  raise "Expected redirect to portfolio_path" unless sess.response.location.end_with?(helpers.portfolio_path(portfolio))
  raise "Expected sticky current_tag_id=#{tag_prt.id}" unless sess.session[:gallery_state][:current_tag_id] == tag_prt.id
  raise "Photo[0] missing tag_prt" unless photos[0].reload.tag_ids.include?(tag_prt.id)
  raise "Photo[1] wrongly received tag_prt" if photos[1].reload.tag_ids.include?(tag_prt.id)
  puts "  [PASS] POST /portfolio/:id/assign_tag verified."

  # 4. POST /exhibition/:id/assign_tag
  exhibition = Exhibition.create!(title: "Ctrl Exhibition #{token}")
  created[:exhibitions] << exhibition.id
  exhibition.exhibition_items.create!(photo: photos[1], position: 1)

  sess.post(helpers.assign_tag_exhibition_path(exhibition), params: { tag_id: tag_exh.id })
  raise "Expected 302 redirect on exhibition assign_tag, got #{sess.status}" unless sess.status == 302
  raise "Expected redirect to exhibition_path" unless sess.response.location.end_with?(helpers.exhibition_path(exhibition))
  raise "Expected sticky current_tag_id=#{tag_exh.id}" unless sess.session[:gallery_state][:current_tag_id] == tag_exh.id
  raise "Photo[1] missing tag_exh" unless photos[1].reload.tag_ids.include?(tag_exh.id)
  puts "  [PASS] POST /exhibition/:id/assign_tag verified."

  # 5. Guarded constraint: blank or nonexistent tag_id
  sess.post(helpers.assign_tag_portfolio_path(portfolio), params: { tag_id: "" })
  raise "Expected 302 redirect on blank tag_id" unless sess.status == 302
  raise "Expected alert flash on blank tag_id" unless sess.flash[:alert].to_s.include?("valid tag")

  sess.post(helpers.assign_tag_exhibition_path(exhibition), params: { tag_id: 999_999_999 })
  raise "Expected 302 redirect on invalid tag_id" unless sess.status == 302
  raise "Expected alert flash on invalid tag_id" unless sess.flash[:alert].to_s.include?("valid tag")
  puts "  [PASS] Blank and nonexistent tag_id guards verified."

  puts "==> All Phase 2 CollectionGangTaggable controller checks passed successfully!"
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
  Exhibition.where(id: created[:exhibitions]).destroy_all
  Portfolio.where(id: created[:portfolios]).destroy_all
  Photo.where(id: created[:photos]).destroy_all
  Catalog.where(id: created[:catalogs]).destroy_all
  Tag.where(id: created[:tags]).destroy_all
  Category.where(id: created[:categories]).destroy_all
  puts "  [CLEANUP] Zero residual test records verified."
end

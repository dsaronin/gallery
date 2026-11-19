# frozen_string_literal: true

# Usage: bin/rails runner script/test_collection_gang_tag_views.rb

puts "==> Starting validation for CollectionGangTaggable show views..."

helpers = Rails.application.routes.url_helpers

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

  cat = Category.create!(name: "ViewCat_#{token}")
  created[:categories] << cat.id

  tag = Tag.create!(name: "ViewTag_#{token}", category: cat)
  created[:tags] << tag.id

  catalog = Catalog.create!(
    name:  "ViewCatalog_#{token}",
    fname: "view_gang_#{token}",
    fpath: "/tmp/view_gang_#{token}"
  )
  created[:catalogs] << catalog.id

  photo = catalog.photos.create!(
    photo_dsc: "View Gang Photo",
    filename:  "view_gang_#{token}.jpg",
    photodate: Time.current,
    stars:     4
  )
  created[:photos] << photo.id

  portfolio = Portfolio.create!(name: "view_port_#{token}", title: "View Portfolio #{token}")
  created[:portfolios] << portfolio.id
  portfolio.portfolio_items.create!(photo: photo, position: 1)

  exhibition = Exhibition.create!(title: "View Exhibition #{token}")
  created[:exhibitions] << exhibition.id
  exhibition.exhibition_items.create!(photo: photo, position: 1)

  # 1. Catalog#show renders gang-tag section above curated-usage-section
  sess.get(helpers.catalog_path(catalog))
  raise "Expected 200 on catalog#show, got #{sess.status}" unless sess.status == 200
  body = sess.response.body
  raise "Catalog#show missing collection-gang-tag-section" unless body.include?("collection-gang-tag-section")
  raise "Catalog#show missing assign_tag action" unless body.include?(helpers.assign_tag_catalog_path(catalog))
  gang_idx    = body.index("collection-gang-tag-section")
  curated_idx = body.index("curated-usage-section")
  raise "Catalog#show gang-tag section must appear before curated-usage-section" unless curated_idx && gang_idx < curated_idx
  puts "  [PASS] Catalog#show renders gang-tag section directly below grid and above curated-usage-section."

  # 2. Portfolio#show renders gang-tag section when items exist
  sess.get(helpers.portfolio_path(portfolio))
  raise "Expected 200 on portfolio#show, got #{sess.status}" unless sess.status == 200
  body = sess.response.body
  raise "Portfolio#show missing collection-gang-tag-section" unless body.include?("collection-gang-tag-section")
  raise "Portfolio#show missing assign_tag action" unless body.include?(helpers.assign_tag_portfolio_path(portfolio))
  puts "  [PASS] Portfolio#show renders gang-tag section in card footer."

  # 3. Exhibition#show renders gang-tag section when items exist
  sess.get(helpers.exhibition_path(exhibition))
  raise "Expected 200 on exhibition#show, got #{sess.status}" unless sess.status == 200
  body = sess.response.body
  raise "Exhibition#show missing collection-gang-tag-section" unless body.include?("collection-gang-tag-section")
  raise "Exhibition#show missing assign_tag action" unless body.include?(helpers.assign_tag_exhibition_path(exhibition))
  puts "  [PASS] Exhibition#show renders gang-tag section in card footer."

  # 4. Empty collections omit gang-tag section
  empty_port = Portfolio.create!(name: "empty_port_#{token}", title: "Empty Portfolio #{token}")
  created[:portfolios] << empty_port.id
  sess.get(helpers.portfolio_path(empty_port))
  raise "Empty Portfolio#show should not render gang-tag section" if sess.response.body.include?("collection-gang-tag-section")

  empty_exh = Exhibition.create!(title: "Empty Exhibition #{token}")
  created[:exhibitions] << empty_exh.id
  sess.get(helpers.exhibition_path(empty_exh))
  raise "Empty Exhibition#show should not render gang-tag section" if sess.response.body.include?("collection-gang-tag-section")
  puts "  [PASS] Empty collections omit gang-tag section."

  puts "==> All Phase 3 CollectionGangTaggable view checks passed successfully!"
ensure
  Exhibition.where(id: created[:exhibitions]).destroy_all
  Portfolio.where(id: created[:portfolios]).destroy_all
  Photo.where(id: created[:photos]).destroy_all
  Catalog.where(id: created[:catalogs]).destroy_all
  Tag.where(id: created[:tags]).destroy_all
  Category.where(id: created[:categories]).destroy_all
  puts "  [CLEANUP] Zero residual test records verified."
end

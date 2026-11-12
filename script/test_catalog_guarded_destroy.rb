# script/test_catalog_guarded_destroy.rb
# Run via: bin/rails runner script/test_catalog_guarded_destroy.rb

puts "=== Testing Photo Associations & CatalogController Guarded Destroy ==="

# 1. Verify Photo associations align with schema (no HABTM photos_portfolio_items lookup)
ActiveRecord::Base.transaction do
  catalog = Catalog.create!(
    name: "Assoc Test Catalog",
    fname: "assoc_test_#{SecureRandom.hex(4)}",
    fpath: "/tmp/assoc_test"
  )
  photo = catalog.photos.create!(
    photo_dsc: "Assoc Test Photo",
    filename: "assoc_#{SecureRandom.hex(4)}.jpg",
    photodate: Time.current,
    stars: 4
  )

  raise "Expected photo.portfolio_items to be empty" unless photo.portfolio_items.empty?
  raise "Expected photo.exhibition_items to be empty" unless photo.exhibition_items.empty?
  raise "Expected photo.portfolios to be empty" unless photo.portfolios.empty?
  raise "Expected photo.exhibitions to be empty" unless photo.exhibitions.empty?

  # Destroying a standalone photo must not raise StatementInvalid for photos_portfolio_items
  photo.destroy!
  raise "Expected photo to be destroyed" unless Photo.where(id: photo.id).empty?

  puts "1. Photo association and destroy checks passed."
  raise ActiveRecord::Rollback
end

original_forgery_setting = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false

begin
# 2. Verify CatalogController#destroy blocks deletion when curated in Portfolio or Exhibition
ActiveRecord::Base.transaction do
  catalog = Catalog.create!(
    name: "Guarded Catalog",
    fname: "guarded_#{SecureRandom.hex(4)}",
    fpath: "/tmp/guarded"
  )
  photo = catalog.photos.create!(
    photo_dsc: "Curated Shot",
    filename: "curated_#{SecureRandom.hex(4)}.jpg",
    photodate: Time.current,
    stars: 5
  )

  portfolio = Portfolio.create!(name: "guard_port_#{SecureRandom.hex(4)}", title: "Guard Test Portfolio")
  portfolio.portfolio_items.create!(photo: photo)

  session = ActionDispatch::Integration::Session.new(Rails.application)
  session.host!("localhost")
  session.delete("/catalog/#{catalog.id}")

  raise "Expected redirect (302) when blocking curated catalog delete, got #{session.status}" unless session.status == 302
  raise "Expected flash alert on blocked delete" unless session.flash[:alert].to_s.include?("Guard Test Portfolio")
  raise "Expected curated catalog ##{catalog.id} NOT to be destroyed" unless Catalog.exists?(catalog.id)
  raise "Expected curated photo ##{photo.id} NOT to be destroyed" unless Photo.exists?(photo.id)

  puts "2. Guarded deletion block (curated catalog preserved) passed."
  raise ActiveRecord::Rollback
end

# 3. Verify CatalogController#destroy succeeds when uncurated and nullifies Talent#cover_id
ActiveRecord::Base.transaction do
  catalog = Catalog.create!(
    name: "Deletable Catalog",
    fname: "deletable_#{SecureRandom.hex(4)}",
    fpath: "/tmp/deletable"
  )
  photo = catalog.photos.create!(
    photo_dsc: "Cover Shot",
    filename: "cover_#{SecureRandom.hex(4)}.jpg",
    photodate: Time.current,
    stars: 3
  )
  talent = Talent.create!(
    talent_code: "T_#{SecureRandom.hex(3)}",
    talent_name: "Test Talent",
    first_name: "Test",
    cover: photo
  )

  session = ActionDispatch::Integration::Session.new(Rails.application)
  session.host!("localhost")
  session.delete("/catalog/#{catalog.id}")

  raise "Expected redirect (302) after deleting uncurated catalog, got #{session.status}" unless session.status == 302
  raise "Expected flash notice on delete" unless session.flash[:notice].to_s.include?("Deleted catalog")
  raise "Expected uncurated catalog ##{catalog.id} to be destroyed" if Catalog.exists?(catalog.id)
  raise "Expected child photo ##{photo.id} to be destroyed" if Photo.exists?(photo.id)
  raise "Expected talent cover_id to be nullified" unless talent.reload.cover_id.nil?

  puts "3. Uncurated catalog destroy and Talent cover nullification passed."
  raise ActiveRecord::Rollback
end
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
end
puts "=== All Guarded Destroy & Photo Association Tests Passed ==="

# script/test_catalog_curation_queries.rb
# Run via: bin/rails runner script/test_catalog_curation_queries.rb

puts "=== Testing Catalog Curation Query Methods ==="

# 1. Non-destructive inspection of existing database state
Catalog.find_each do |catalog|
  is_curated = catalog.curated?
  portfolios = catalog.curated_portfolios.pluck(:title)
  exhibitions = catalog.curated_exhibitions.pluck(:title)
  puts "Catalog ##{catalog.id} ('#{catalog.name}'): curated?=#{is_curated}, portfolios=#{portfolios.inspect}, exhibitions=#{exhibitions.inspect}"
end

# 2. Isolated transactional test verifying false -> true -> false transitions
ActiveRecord::Base.transaction do
  catalog = Catalog.create!(name: "Temp Test Catalog", fname: "temp_test_#{SecureRandom.hex(4)}", fpath: "/tmp/test")
  photo = catalog.photos.create!(
    photo_dsc: "Test Shot",
    filename: "test_#{SecureRandom.hex(4)}.jpg",
    photodate: Time.current,
    stars: 4
  )

  raise "Expected curated? to be false for fresh catalog" if catalog.curated?
  raise "Expected curated_portfolios to be empty" unless catalog.curated_portfolios.empty?
  raise "Expected curated_exhibitions to be empty" unless catalog.curated_exhibitions.empty?

  portfolio = Portfolio.create!(name: "temp_port_#{SecureRandom.hex(4)}", title: "Temp Test Portfolio")
  portfolio.portfolio_items.create!(photo: photo)

  raise "Expected curated? to be true after adding to portfolio" unless catalog.curated?
  raise "Expected curated_portfolios to include Temp Test Portfolio" unless catalog.curated_portfolios.pluck(:id) == [portfolio.id]

  portfolio.portfolio_items.destroy_all
  raise "Expected curated? to return to false after clearing portfolio items" if catalog.curated?

  puts "Transactional assertions passed (rolled back cleanly)."
  raise ActiveRecord::Rollback
end

puts "=== All Catalog Curation Query Tests Passed ==="

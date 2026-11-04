# script/test_integration.rb
puts "=== Starting Phase 3 Integration Verification ==="

photo = Photo.first
raise "Prerequisite missing: No photos found in database. Ingest photos first." unless photo
puts "1. Photo available: ID #{photo.id} (#{photo.filename}, #{photo.photodate})"

ActiveRecord::Base.transaction do
  # 2. Instantiate Base Presentation & Location Models
  placard = Placard.create!(
    title: "Curatorial Statement",
    artist_name: Gallery::Environ::DEFAULT_ARTIST_NAME,
    cc_license: :cc_by_sa,
    copyright_year: 2024,
    price: 150
  )
  puts "2. Placard created: ID #{placard.id} [license: #{placard.cc_license}]"

  venue = Venue.create!(
    name: "Pacific Fine Arts Gallery",
    venue_type: :commercial_gallery,
    wall_linear_meters: 45.5,
    rate_per_day: 250,
    contact_name: "Gallery Director"
  )
  puts "3. Venue created: ID #{venue.id} [type: #{venue.venue_type}, wall: #{venue.wall_linear_meters}m]"

  # 3. Assemble Portfolio & Verify Automatic Position + Share Token
  portfolio = Portfolio.create!(
    name: "retrospective_2026",
    title: "Cinematic Natural Light Retrospective",
    placard: placard
  )
  raise "Portfolio share_token generation failed" if portfolio.share_token.blank?
  puts "4. Portfolio created: '#{portfolio.title}' [share_token: #{portfolio.share_token} (len: #{portfolio.share_token.length})]"

  item1 = portfolio.portfolio_items.create!(photo: photo)
  raise "Positionable failed: expected position 1, got #{item1.position}" unless item1.position == 1
  puts "5. PortfolioItem created: ID #{item1.id} [auto-position: #{item1.position}]"

  # 4. Stage Exhibition & ExhibitionItem
  exhibition = Exhibition.create!(
    title: "Expressions in Light",
    portfolio: portfolio,
    venue: venue,
    placard: placard,
    sales_policy: :direct_inquiry,
    budget: 5000,
    total_expenses: 1200
  )
  puts "6. Exhibition staged: ID #{exhibition.id} [policy: #{exhibition.sales_policy}]"

  ex_item = exhibition.exhibition_items.create!(portfolio_item: item1)
  raise "Positionable on ExhibitionItem failed" unless ex_item.position == 1
  puts "7. ExhibitionItem created: ID #{ex_item.id} [auto-position: #{ex_item.position}]"

  # 5. Schedule Showing & Validate DateRangeValidatable
  showing = Showing.new(
    exhibition: exhibition,
    venue: venue,
    start_date: Date.current,
    end_date: Date.current - 2.days # Invalid date range
  )

  if showing.valid?
    raise "DateRangeValidatable FAILED: accepted end_date < start_date"
  else
    puts "8. DateRangeValidatable verified: rejected inverted range ('#{showing.errors[:end_date].first}')"
  end

  # Fix showing dates and persist
  showing.end_date = Date.current + 14.days
  showing.save!
  puts "9. Showing scheduled: ID #{showing.id} (#{showing.start_date} to #{showing.end_date})"

  # 6. Reconcile Circular Reference (Exhibition -> Showing)
  exhibition.update!(showing: showing)
  puts "10. Circular reference resolved: exhibition.showing_id = #{exhibition.reload.showing_id}"

  # 7. Roll back all created records to leave the database pristine
  puts "11. Rolling back transaction to purge test records..."
  raise ActiveRecord::Rollback
end

# Verification of clean state (photo count remains untouched, new models rolled back)
remaining = [Placard, Venue, Portfolio, PortfolioItem, Exhibition, ExhibitionItem, Showing].map(&:count).sum
puts "=== Verification Complete. Unpersisted residual records in DB: #{remaining} ==="

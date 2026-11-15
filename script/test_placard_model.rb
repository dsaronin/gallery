# frozen_string_literal: true

# script/test_placard_model.rb
# Run via: bin/rails runner script/test_placard_model.rb

require "securerandom"

puts "=== Testing Placard Model, Dual-Track Cascades, Fallbacks & Seeding ==="

PlacardData = Gallery::Environ::PlacardData

# 1. Verify seeded Mock Portfolio Placard
mock_portfolio = Portfolio.find_by(name: "Mock Portfolio")
raise "Expected seeded 'Mock Portfolio' to exist" unless mock_portfolio
raise "Expected 'Mock Portfolio' to have a persisted Placard" unless mock_portfolio.placard

seeded_pd = mock_portfolio.placard_data
raise "Expected seeded medium to be set" unless seeded_pd.medium.include?("Archival Pigment Print")
raise "Expected seeded cc_license_key to be :cc_by_nc_nd" unless seeded_pd.cc_license_key == :cc_by_nc_nd
raise "Expected seeded price to be 450" unless seeded_pd.price == 450
puts "1. Seeded Mock Portfolio Placard verified (ID: #{mock_portfolio.placard.id})."

created_ids = {
  catalog_id: nil,
  photo_id: nil,
  portfolio_id: nil,
  portfolio_item_id: nil,
  exhibition_id: nil,
  exhibition_item_id: nil,
  placard_ids: []
}

begin
  ActiveRecord::Base.transaction do
    rand_suffix = SecureRandom.hex(4)

    # 2. Verify unpersisted <Collection> class-level fallback PlacardData
    bare_portfolio = Portfolio.create!(name: "Bare Port #{rand_suffix}", title: "Bare Portfolio Title")
    created_ids[:portfolio_id] = bare_portfolio.id
    raise "Expected bare_portfolio.placard to be nil" unless bare_portfolio.placard.nil?

    bare_pd = bare_portfolio.placard_data
    raise "Expected fallback title 'Bare Portfolio Title'" unless bare_pd.title == "Bare Portfolio Title"
    raise "Expected fallback name alias to match" unless bare_pd.name == "Bare Portfolio Title"
    raise "Expected fallback artist_name to match DEFAULT_ARTIST_NAME" unless bare_pd.artist_name == Gallery::Environ::DEFAULT_ARTIST_NAME
    raise "Expected fallback provenance to be :default" unless bare_pd.default?(:artist_name)
    puts "2. Unpersisted <Collection> class-level fallback PlacardData verified."

    # 3. Build full dual-track chain:
    # Photo -> Portfolio & PortfolioItem -> Exhibition & ExhibitionItem -> Placard overrides
    catalog = Catalog.create!(
      name:  "Cascade Cat #{rand_suffix}",
      fname: "casc_cat_#{rand_suffix}",
      fpath: "/tmp/casc_cat_#{rand_suffix}"
    )
    created_ids[:catalog_id] = catalog.id

    photo = Photo.create!(
      catalog:   catalog,
      photo_dsc: "Intrinsic Photo Title",
      filename:  "CASC_#{rand_suffix}.NEF",
      photodate: Time.zone.parse("2024-06-15 12:00:00"),
      latitude:  37.8044,
      longitude: -122.2712,
      notes:     "Intrinsic photo notes"
    )
    created_ids[:photo_id] = photo.id

    # Attach persisted Placard to Portfolio (COLLECTION track level 1)
    port_placard = Placard.create!(
      title:              "Portfolio Master Title",
      artist_name:        "Daudi Amani",
      medium:             "Silver Gelatin Print",
      dimensions_display: "30 x 40 cm",
      price:              300,
      cc_license:         :cc_by
    )
    created_ids[:placard_ids] << port_placard.id
    bare_portfolio.update!(placard: port_placard)

    # Create PortfolioItem with persisted Placard (ITEM track level 1)
    pi_placard = Placard.create!(
      title:            "Portfolio Item Custom Title",
      location_display: "Oakland Hills, CA"
    )
    created_ids[:placard_ids] << pi_placard.id
    portfolio_item = PortfolioItem.create!(
      portfolio: bare_portfolio,
      photo:     photo,
      placard:   pi_placard
    )
    created_ids[:portfolio_item_id] = portfolio_item.id

    pi_pd = portfolio_item.placard_data
    raise "Expected PortfolioItem title from pi_placard" unless pi_pd.title == "Portfolio Item Custom Title"
    raise "Expected PortfolioItem year cascaded from Photo" unless pi_pd.date_created_display == "2024"
    raise "Expected PortfolioItem location overridden by pi_placard" unless pi_pd.location_display == "Oakland Hills, CA"
    raise "Expected PortfolioItem medium cascaded from Portfolio" unless pi_pd.medium == "Silver Gelatin Print"
    raise "Expected PortfolioItem medium to be :cascaded" unless pi_pd.cascaded?(:medium)
    puts "3. Portfolio & PortfolioItem dual-track cascade verified."

    # Create Exhibition linked to Portfolio with Exhibition Placard override (COLLECTION track level 2)
    exh_placard = Placard.create!(
      medium:     "Platinum Palladium Print",
      price:      650,
      cc_license: :cc_by_sa
    )
    created_ids[:placard_ids] << exh_placard.id
    exhibition = Exhibition.create!(
      title:     "Autumn Exhibition #{rand_suffix}",
      portfolio: bare_portfolio,
      placard:   exh_placard
    )
    created_ids[:exhibition_id] = exhibition.id

    exh_pd = exhibition.placard_data
    raise "Expected Exhibition medium overridden to 'Platinum Palladium Print'" unless exh_pd.medium == "Platinum Palladium Print"
    raise "Expected Exhibition medium to be :direct" unless exh_pd.direct?(:medium)
    raise "Expected Exhibition artist_name cascaded from Portfolio ('Daudi Amani')" unless exh_pd.artist_name == "Daudi Amani"
    raise "Expected Exhibition artist_name to be :cascaded" unless exh_pd.cascaded?(:artist_name)
    raise "Expected Exhibition dimensions cascaded from Portfolio ('30 x 40 cm')" unless exh_pd.dimensions_display == "30 x 40 cm"
    puts "4. Exhibition COLLECTION track cascade & overrides verified."

    # Create ExhibitionItem with final Placard override (highest/dominant level)
    ei_placard = Placard.create!(
      subtitle: "Special Exhibition Edition",
      price:    800
    )
    created_ids[:placard_ids] << ei_placard.id
    exhibition_item = ExhibitionItem.create!(
      exhibition: exhibition,
      photo:      photo,
      placard:    ei_placard
    )
    created_ids[:exhibition_item_id] = exhibition_item.id

    final_pd = exhibition_item.placard_data
    # ITEM track checks:
    raise "Expected title cascaded from PortfolioItem ('Portfolio Item Custom Title')" unless final_pd.title == "Portfolio Item Custom Title"
    raise "Expected title to be :cascaded" unless final_pd.cascaded?(:title)
    raise "Expected location cascaded from PortfolioItem ('Oakland Hills, CA')" unless final_pd.location_display == "Oakland Hills, CA"
    raise "Expected year cascaded from Photo ('2024')" unless final_pd.date_created_display == "2024"
    raise "Expected curatorial_notes cascaded from Photo ('Intrinsic photo notes')" unless final_pd.curatorial_notes == "Intrinsic photo notes"
    raise "Expected subtitle directly set on ExhibitionItem Placard" unless final_pd.subtitle == "Special Exhibition Edition"
    raise "Expected subtitle to be :direct" unless final_pd.direct?(:subtitle)
    # COLLECTION track checks:
    raise "Expected medium cascaded from Exhibition ('Platinum Palladium Print')" unless final_pd.medium == "Platinum Palladium Print"
    raise "Expected medium to be :cascaded" unless final_pd.cascaded?(:medium)
    raise "Expected artist_name cascaded from Portfolio ('Daudi Amani')" unless final_pd.artist_name == "Daudi Amani"
    raise "Expected cc_license_key cascaded from Exhibition (:cc_by_sa)" unless final_pd.cc_license_key == :cc_by_sa
    raise "Expected price overridden directly on ExhibitionItem Placard (800)" unless final_pd.price == 800
    raise "Expected price to be :direct" unless final_pd.direct?(:price)
    puts "5. Full ExhibitionItem end-to-end dual-track cascade & provenance verified."

    raise ActiveRecord::Rollback
  end
ensure
  ExhibitionItem.where(id: created_ids[:exhibition_item_id]).delete_all if created_ids[:exhibition_item_id]
  Exhibition.where(id: created_ids[:exhibition_id]).delete_all if created_ids[:exhibition_id]
  PortfolioItem.where(id: created_ids[:portfolio_item_id]).delete_all if created_ids[:portfolio_item_id]
  Portfolio.where(id: created_ids[:portfolio_id]).delete_all if created_ids[:portfolio_id]
  Photo.where(id: created_ids[:photo_id]).delete_all if created_ids[:photo_id]
  Catalog.where(id: created_ids[:catalog_id]).delete_all if created_ids[:catalog_id]
  Placard.where(id: created_ids[:placard_ids]).delete_all if created_ids[:placard_ids].any?
end

raise "Residual Placards detected!" if created_ids[:placard_ids].any? && Placard.where(id: created_ids[:placard_ids]).exists?
raise "Residual Exhibition detected!" if created_ids[:exhibition_id] && Exhibition.exists?(created_ids[:exhibition_id])
raise "Residual Portfolio detected!" if created_ids[:portfolio_id] && Portfolio.exists?(created_ids[:portfolio_id])
raise "Residual Photo detected!" if created_ids[:photo_id] && Photo.exists?(created_ids[:photo_id])
raise "Residual Catalog detected!" if created_ids[:catalog_id] && Catalog.exists?(created_ids[:catalog_id])
puts "6. Zero residual test records verified."

puts "=== All Phase 2 Placard Model & Cascade Tests Passed ==="

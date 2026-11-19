# frozen_string_literal: true

# script/test_positionable_navigation.rb
# Run via: bin/rails runner script/test_positionable_navigation.rb

require "securerandom"

puts "=== Testing Gallery::Environ Navigation Glyphs & Positionable Sibling Traversal ==="

# 1. Verify Gallery::Environ navigation glyph constants
raise "Expected NAV_PREV_GLYPH to be '◀'" unless Gallery::Environ::NAV_PREV_GLYPH == "◀"
raise "Expected NAV_NEXT_GLYPH to be '▶'" unless Gallery::Environ::NAV_NEXT_GLYPH == "▶"
puts "1. Gallery::Environ navigation glyph constants verified."

created_ids = {
  catalog_id: nil,
  photo_ids: [],
  portfolio_ids: [],
  portfolio_item_ids: [],
  exhibition_ids: [],
  exhibition_item_ids: []
}

begin
  ActiveRecord::Base.transaction do
    rand_suffix = SecureRandom.hex(4)

    catalog = Catalog.create!(
      name:  "PosNav Cat #{rand_suffix}",
      fname: "posnav_cat_#{rand_suffix}",
      fpath: "/tmp/posnav_cat_#{rand_suffix}"
    )
    created_ids[:catalog_id] = catalog.id

    photos = (1..4).map do |idx|
      p = Photo.create!(
        catalog:   catalog,
        photo_dsc: "PosNav Photo #{idx}",
        filename:  "POSNAV_#{idx}_#{rand_suffix}.NEF",
        photodate: Time.zone.parse("2025-05-0#{idx} 10:00:00")
      )
      created_ids[:photo_ids] << p.id
      p
    end

    # 2. PortfolioItem 3-item sequence & boundary clamping
    portfolio_a = Portfolio.create!(
      name:  "posnav_port_a_#{rand_suffix}",
      title: "PosNav Portfolio A #{rand_suffix}"
    )
    created_ids[:portfolio_ids] << portfolio_a.id

    pi_1 = PortfolioItem.create!(portfolio: portfolio_a, photo: photos[0])
    pi_2 = PortfolioItem.create!(portfolio: portfolio_a, photo: photos[1])
    pi_3 = PortfolioItem.create!(portfolio: portfolio_a, photo: photos[2])
    created_ids[:portfolio_item_ids].concat([pi_1.id, pi_2.id, pi_3.id])

    raise "Expected pi_1.prev_item to be nil" unless pi_1.prev_item.nil?
    raise "Expected pi_1.next_item to be pi_2" unless pi_1.next_item == pi_2
    raise "Expected pi_2.prev_item to be pi_1" unless pi_2.prev_item == pi_1
    raise "Expected pi_2.next_item to be pi_3" unless pi_2.next_item == pi_3
    raise "Expected pi_3.prev_item to be pi_2" unless pi_3.prev_item == pi_2
    raise "Expected pi_3.next_item to be nil" unless pi_3.next_item.nil?
    puts "2. PortfolioItem 3-item traversal & clamped boundaries passed."

    # 3. ExhibitionItem 3-item sequence & boundary clamping
    exhibition_a = Exhibition.create!(title: "PosNav Exhibition A #{rand_suffix}")
    created_ids[:exhibition_ids] << exhibition_a.id

    ei_1 = ExhibitionItem.create!(exhibition: exhibition_a, photo: photos[0])
    ei_2 = ExhibitionItem.create!(exhibition: exhibition_a, photo: photos[1])
    ei_3 = ExhibitionItem.create!(exhibition: exhibition_a, photo: photos[2])
    created_ids[:exhibition_item_ids].concat([ei_1.id, ei_2.id, ei_3.id])

    raise "Expected ei_1.prev_item to be nil" unless ei_1.prev_item.nil?
    raise "Expected ei_1.next_item to be ei_2" unless ei_1.next_item == ei_2
    raise "Expected ei_2.prev_item to be ei_1" unless ei_2.prev_item == ei_1
    raise "Expected ei_2.next_item to be ei_3" unless ei_2.next_item == ei_3
    raise "Expected ei_3.prev_item to be ei_2" unless ei_3.prev_item == ei_2
    raise "Expected ei_3.next_item to be nil" unless ei_3.next_item.nil?
    puts "3. ExhibitionItem 3-item traversal & clamped boundaries passed."

    # 4. Guarded constraint: Non-contiguous positions (gap after middle item removal)
    ei_2.destroy!
    raise "Expected ei_1.next_item to skip gap to ei_3" unless ei_1.next_item == ei_3
    raise "Expected ei_3.prev_item to skip gap to ei_1" unless ei_3.prev_item == ei_1
    puts "4. Non-contiguous position gap traversal passed."

    # 5. Guarded constraint: Scope isolation & single-item collection
    portfolio_b = Portfolio.create!(
      name:  "posnav_port_b_#{rand_suffix}",
      title: "PosNav Portfolio B #{rand_suffix}"
    )
    created_ids[:portfolio_ids] << portfolio_b.id

    pi_solo = PortfolioItem.create!(portfolio: portfolio_b, photo: photos[3])
    created_ids[:portfolio_item_ids] << pi_solo.id

    raise "Expected single-item pi_solo.prev_item to be nil" unless pi_solo.prev_item.nil?
    raise "Expected single-item pi_solo.next_item to be nil" unless pi_solo.next_item.nil?

    unpersisted_pi = PortfolioItem.new
    raise "Expected unpersisted PortfolioItem.prev_item to be nil" unless unpersisted_pi.prev_item.nil?
    raise "Expected unpersisted PortfolioItem.next_item to be nil" unless unpersisted_pi.next_item.nil?
    puts "5. Scope isolation, single-item collection & unpersisted guards passed."

    # 6. Adjacent position swap mechanics (move_higher! / move_lower!) & boundary clamping
    raise "Expected pi_1.move_higher! to return false at top boundary" unless pi_1.move_higher! == false
    raise "Expected pi_1 position to remain 1" unless pi_1.reload.position == 1

    raise "Expected pi_3.move_lower! to return false at bottom boundary" unless pi_3.move_lower! == false
    raise "Expected pi_3 position to remain 3" unless pi_3.reload.position == 3

    raise "Expected pi_2.move_higher! to return true" unless pi_2.move_higher! == true
    raise "Expected pi_2 position to become 1" unless pi_2.reload.position == 1
    raise "Expected pi_1 position to become 2" unless pi_1.reload.position == 2
    raise "Expected portfolio_a ordered items to be [pi_2, pi_1, pi_3]" unless portfolio_a.portfolio_items.reload.to_a == [pi_2, pi_1, pi_3]

    raise "Expected pi_2.move_lower! to return true" unless pi_2.move_lower! == true
    raise "Expected pi_2 position to return to 2" unless pi_2.reload.position == 2
    raise "Expected pi_1 position to return to 1" unless pi_1.reload.position == 1

    # Verify ExhibitionItem swap across non-contiguous positions (ei_1 at 1, ei_3 at 3)
    raise "Expected ei_3.move_higher! to return true" unless ei_3.move_higher! == true
    raise "Expected ei_3 position to become 1" unless ei_3.reload.position == 1
    raise "Expected ei_1 position to become 3" unless ei_1.reload.position == 3
    puts "6. Positionable move_higher! / move_lower! SQLite-safe swaps & boundary guards passed."

    raise ActiveRecord::Rollback
  end
ensure
  ExhibitionItem.where(id: created_ids[:exhibition_item_ids]).delete_all if created_ids[:exhibition_item_ids].any?
  Exhibition.where(id: created_ids[:exhibition_ids]).delete_all if created_ids[:exhibition_ids].any?
  PortfolioItem.where(id: created_ids[:portfolio_item_ids]).delete_all if created_ids[:portfolio_item_ids].any?
  Portfolio.where(id: created_ids[:portfolio_ids]).delete_all if created_ids[:portfolio_ids].any?
  Photo.where(id: created_ids[:photo_ids]).delete_all if created_ids[:photo_ids].any?
  Catalog.where(id: created_ids[:catalog_id]).delete_all if created_ids[:catalog_id]
end

raise "Residual ExhibitionItems detected!" if ExhibitionItem.where(id: created_ids[:exhibition_item_ids]).exists?
raise "Residual Exhibitions detected!" if Exhibition.where(id: created_ids[:exhibition_ids]).exists?
raise "Residual PortfolioItems detected!" if PortfolioItem.where(id: created_ids[:portfolio_item_ids]).exists?
raise "Residual Portfolios detected!" if Portfolio.where(id: created_ids[:portfolio_ids]).exists?
raise "Residual Photos detected!" if Photo.where(id: created_ids[:photo_ids]).exists?
raise "Residual Catalog detected!" if created_ids[:catalog_id] && Catalog.exists?(created_ids[:catalog_id])
puts "7. Zero residual test records verified."

puts "=== All Step 1 Positionable Navigation Tests Passed ==="

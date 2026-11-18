# frozen_string_literal: true

# script/test_placard_itemcard_nav_controller.rb
# Run via: bin/rails runner script/test_placard_itemcard_nav_controller.rb

require "securerandom"

puts "=== Testing PlacardController#itemcard Sibling Navigation Resolution ==="

helpers = Rails.application.routes.url_helpers
original_forgery_setting = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false

created_ids = {
  catalog_id: nil,
  photo_ids: [],
  portfolio_id: nil,
  portfolio_item_ids: [],
  exhibition_id: nil,
  exhibition_item_ids: [],
  placard_ids: []
}

begin
  ActiveRecord::Base.transaction do
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host!("localhost")
    rand_suffix = SecureRandom.hex(4)

    catalog = Catalog.create!(
      name:  "ItemNav Cat #{rand_suffix}",
      fname: "itemnav_cat_#{rand_suffix}",
      fpath: "/tmp/itemnav_cat_#{rand_suffix}"
    )
    created_ids[:catalog_id] = catalog.id

    photos = (1..3).map do |idx|
      p = Photo.create!(
        catalog:   catalog,
        photo_dsc: "ItemNav Photo #{idx}",
        filename:  "ITEMNAV_#{idx}_#{rand_suffix}.NEF",
        photodate: Time.zone.parse("2025-06-0#{idx} 10:00:00")
      )
      created_ids[:photo_ids] << p.id
      p
    end

    # 1. ExhibitionItem sequence via query-param route
    exhibition = Exhibition.create!(title: "ItemNav Exhibition #{rand_suffix}")
    created_ids[:exhibition_id] = exhibition.id

    ei_1 = ExhibitionItem.create!(exhibition: exhibition, photo: photos[0])
    ei_2 = ExhibitionItem.create!(exhibition: exhibition, photo: photos[1])
    ei_3 = ExhibitionItem.create!(exhibition: exhibition, photo: photos[2])
    created_ids[:exhibition_item_ids].concat([ei_1.id, ei_2.id, ei_3.id])

    # First item (clamped prev)
    session.get(helpers.itemcard_placard_index_path(target_type: "ExhibitionItem", target_id: ei_1.id))
    raise "Expected 200 for ei_1 itemcard, got #{session.status}" unless session.status == 200
    ctrl = session.controller
    raise "Expected @show_item_nav true for ei_1" unless ctrl.instance_variable_get(:@show_item_nav) == true
    raise "Expected @prev_item nil for ei_1" unless ctrl.instance_variable_get(:@prev_item).nil?
    raise "Expected @next_item == ei_2 for ei_1" unless ctrl.instance_variable_get(:@next_item) == ei_2
    raise "Expected disabled nav-prev span on ei_1" unless session.body.include?("item-nav-btn nav-prev disabled")
    raise "Expected active nav-next link to ei_2 on ei_1" unless session.body.include?("target_id=#{ei_2.id}&amp;target_type=ExhibitionItem") || session.body.include?("target_type=ExhibitionItem&amp;target_id=#{ei_2.id}")

    # Middle item (both prev and next active)
    session.get(helpers.itemcard_placard_index_path(target_type: "ExhibitionItem", target_id: ei_2.id))
    raise "Expected 200 for ei_2 itemcard, got #{session.status}" unless session.status == 200
    ctrl = session.controller
    raise "Expected @show_item_nav true for ei_2" unless ctrl.instance_variable_get(:@show_item_nav) == true
    raise "Expected @prev_item == ei_1 for ei_2" unless ctrl.instance_variable_get(:@prev_item) == ei_1
    raise "Expected @next_item == ei_3 for ei_2" unless ctrl.instance_variable_get(:@next_item) == ei_3
    raise "Expected no disabled nav buttons on ei_2" if session.body.include?("item-nav-btn nav-prev disabled") || session.body.include?("item-nav-btn nav-next disabled")

    # Last item (clamped next)
    session.get(helpers.itemcard_placard_index_path(target_type: "ExhibitionItem", target_id: ei_3.id))
    raise "Expected 200 for ei_3 itemcard, got #{session.status}" unless session.status == 200
    ctrl = session.controller
    raise "Expected @show_item_nav true for ei_3" unless ctrl.instance_variable_get(:@show_item_nav) == true
    raise "Expected @prev_item == ei_2 for ei_3" unless ctrl.instance_variable_get(:@prev_item) == ei_2
    raise "Expected @next_item nil for ei_3" unless ctrl.instance_variable_get(:@next_item).nil?
    raise "Expected disabled nav-next span on ei_3" unless session.body.include?("item-nav-btn nav-next disabled")
    puts "1. ExhibitionItem first/middle/last itemcard controller & DOM rendering passed."

    # 2. PortfolioItem sequence + member route (/placard/:id/itemcard without target params)
    portfolio = Portfolio.create!(
      name:  "itemnav_port_#{rand_suffix}",
      title: "ItemNav Portfolio #{rand_suffix}"
    )
    created_ids[:portfolio_id] = portfolio.id

    pi_1 = PortfolioItem.create!(portfolio: portfolio, photo: photos[0])
    pi_2 = PortfolioItem.create!(portfolio: portfolio, photo: photos[1])
    created_ids[:portfolio_item_ids].concat([pi_1.id, pi_2.id])

    placard_pi2 = Placard.create!(title: "Direct Override PI2 #{rand_suffix}")
    created_ids[:placard_ids] << placard_pi2.id
    pi_2.update!(placard: placard_pi2)

    session.get(helpers.itemcard_placard_path(placard_pi2))
    raise "Expected 200 for member itemcard_placard_path, got #{session.status}" unless session.status == 200
    ctrl = session.controller
    raise "Expected @target inferred as pi_2" unless ctrl.instance_variable_get(:@target) == pi_2
    raise "Expected @parent_collection == portfolio" unless ctrl.instance_variable_get(:@parent_collection) == portfolio
    raise "Expected @show_item_nav true for pi_2" unless ctrl.instance_variable_get(:@show_item_nav) == true
    raise "Expected @prev_item == pi_1" unless ctrl.instance_variable_get(:@prev_item) == pi_1
    raise "Expected @next_item nil for pi_2" unless ctrl.instance_variable_get(:@next_item).nil?
    puts "2. PortfolioItem member route (/placard/:id/itemcard) inference & nav passed."

    # 3. Guarded constraint: Collection-level itemcards omit item navigation
    session.get(helpers.itemcard_placard_index_path(target_type: "Exhibition", target_id: exhibition.id))
    raise "Expected 200 for Exhibition itemcard, got #{session.status}" unless session.status == 200
    ctrl = session.controller
    raise "Expected @show_item_nav false for Exhibition" unless ctrl.instance_variable_get(:@show_item_nav) == false
    raise "Expected @prev_item nil for Exhibition" unless ctrl.instance_variable_get(:@prev_item).nil?
    raise "Expected @next_item nil for Exhibition" unless ctrl.instance_variable_get(:@next_item).nil?
    raise "Expected .item-nav-group omitted from Exhibition itemcard HTML" if session.body.include?("item-nav-group")

    session.get(helpers.itemcard_placard_index_path(target_type: "Portfolio", target_id: portfolio.id))
    raise "Expected 200 for Portfolio itemcard, got #{session.status}" unless session.status == 200
    ctrl = session.controller
    raise "Expected @show_item_nav false for Portfolio" unless ctrl.instance_variable_get(:@show_item_nav) == false
    puts "3. Guarded collection-level itemcard omission passed."

    # 4. Guarded constraint: Invalid/missing target redirects cleanly
    session.get(helpers.itemcard_placard_index_path(target_type: "InvalidType", target_id: 1))
    raise "Expected 302 redirect on invalid target_type, got #{session.status}" unless session.status == 302
    raise "Expected alert flash on invalid target_type" if session.flash[:alert].blank?
    puts "4. Guarded invalid target redirect passed."

    raise ActiveRecord::Rollback
  end
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
  ExhibitionItem.where(id: created_ids[:exhibition_item_ids]).delete_all if created_ids[:exhibition_item_ids].any?
  Exhibition.where(id: created_ids[:exhibition_id]).delete_all if created_ids[:exhibition_id]
  PortfolioItem.where(id: created_ids[:portfolio_item_ids]).delete_all if created_ids[:portfolio_item_ids].any?
  Portfolio.where(id: created_ids[:portfolio_id]).delete_all if created_ids[:portfolio_id]
  Photo.where(id: created_ids[:photo_ids]).delete_all if created_ids[:photo_ids].any?
  Catalog.where(id: created_ids[:catalog_id]).delete_all if created_ids[:catalog_id]
  Placard.where(id: created_ids[:placard_ids]).delete_all if created_ids[:placard_ids].any?
end

raise "Residual ExhibitionItems detected!" if ExhibitionItem.where(id: created_ids[:exhibition_item_ids]).exists?
raise "Residual Exhibitions detected!" if created_ids[:exhibition_id] && Exhibition.exists?(created_ids[:exhibition_id])
raise "Residual PortfolioItems detected!" if PortfolioItem.where(id: created_ids[:portfolio_item_ids]).exists?
raise "Residual Portfolios detected!" if created_ids[:portfolio_id] && Portfolio.exists?(created_ids[:portfolio_id])
raise "Residual Photos detected!" if Photo.where(id: created_ids[:photo_ids]).exists?
raise "Residual Catalog detected!" if created_ids[:catalog_id] && Catalog.exists?(created_ids[:catalog_id])
raise "Residual Placards detected!" if created_ids[:placard_ids].any? && Placard.where(id: created_ids[:placard_ids]).exists?
puts "5. Zero residual test records verified."

puts "=== All Step 2 PlacardController#itemcard Navigation Tests Passed ==="

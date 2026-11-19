# frozen_string_literal: true

# script/test_collection_item_ordering.rb
# Run via: bin/rails runner script/test_collection_item_ordering.rb

require "securerandom"

puts "=== Testing Portfolio & Exhibition Item Ordering Routes & Controller Actions ==="

helpers = Rails.application.routes.url_helpers

# 1. Verify singular member route helpers
raise "Expected move_item_portfolio_path(1) to be /portfolio/1/move_item" unless helpers.move_item_portfolio_path(1) == "/portfolio/1/move_item"
raise "Expected move_item_exhibition_path(1) to be /exhibition/1/move_item" unless helpers.move_item_exhibition_path(1) == "/exhibition/1/move_item"
puts "1. Singular move_item route helpers verified."

original_forgery_setting = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false

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
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host!("localhost")
    rand_suffix = SecureRandom.hex(4)

    catalog = Catalog.create!(
      name:  "OrderCat #{rand_suffix}",
      fname: "order_cat_#{rand_suffix}",
      fpath: "/tmp/order_cat_#{rand_suffix}"
    )
    created_ids[:catalog_id] = catalog.id

    photos = (1..3).map do |idx|
      p = Photo.create!(
        catalog:   catalog,
        photo_dsc: "Order Photo #{idx}",
        filename:  "ORDER_#{idx}_#{rand_suffix}.NEF",
        photodate: Time.zone.parse("2025-07-0#{idx} 10:00:00")
      )
      created_ids[:photo_ids] << p.id
      p
    end

    # 2. Portfolio move_item happy paths & boundary guards
    portfolio_a = Portfolio.create!(
      name:  "order_port_a_#{rand_suffix}",
      title: "Order Portfolio A #{rand_suffix}"
    )
    portfolio_b = Portfolio.create!(
      name:  "order_port_b_#{rand_suffix}",
      title: "Order Portfolio B #{rand_suffix}"
    )
    created_ids[:portfolio_ids].concat([portfolio_a.id, portfolio_b.id])

    pi_1 = PortfolioItem.create!(portfolio: portfolio_a, photo: photos[0])
    pi_2 = PortfolioItem.create!(portfolio: portfolio_a, photo: photos[1])
    pi_3 = PortfolioItem.create!(portfolio: portfolio_a, photo: photos[2])
    pi_other = PortfolioItem.create!(portfolio: portfolio_b, photo: photos[0])
    created_ids[:portfolio_item_ids].concat([pi_1.id, pi_2.id, pi_3.id, pi_other.id])

    # Move pi_2 higher -> [pi_2, pi_1, pi_3]
    session.patch(helpers.move_item_portfolio_path(portfolio_a), params: { item_id: pi_2.id, direction: "higher" })
    raise "Expected 302 redirect on PATCH move_item_portfolio_path, got #{session.status}" unless session.status == 302
    raise "Expected portfolio_a order [pi_2, pi_1, pi_3]" unless portfolio_a.portfolio_items.reload.to_a == [pi_2, pi_1, pi_3]

    # Move pi_2 lower -> [pi_1, pi_2, pi_3]
    session.patch(helpers.move_item_portfolio_path(portfolio_a), params: { item_id: pi_2.id, direction: "lower" })
    raise "Expected 302 redirect on PATCH move_item_portfolio_path, got #{session.status}" unless session.status == 302
    raise "Expected portfolio_a order [pi_1, pi_2, pi_3]" unless portfolio_a.portfolio_items.reload.to_a == [pi_1, pi_2, pi_3]

    # Clamped boundaries (no-op)
    session.patch(helpers.move_item_portfolio_path(portfolio_a), params: { item_id: pi_1.id, direction: "higher" })
    raise "Expected 302 redirect on clamped higher move" unless session.status == 302
    raise "Expected order unchanged after clamped higher move" unless portfolio_a.portfolio_items.reload.to_a == [pi_1, pi_2, pi_3]

    session.patch(helpers.move_item_portfolio_path(portfolio_a), params: { item_id: pi_3.id, direction: "lower" })
    raise "Expected 302 redirect on clamped lower move" unless session.status == 302
    raise "Expected order unchanged after clamped lower move" unless portfolio_a.portfolio_items.reload.to_a == [pi_1, pi_2, pi_3]

    # Guarded constraints: cross-portfolio item_id & invalid direction
    session.patch(helpers.move_item_portfolio_path(portfolio_a), params: { item_id: pi_other.id, direction: "higher" })
    raise "Expected 302 redirect on out-of-scope item_id" unless session.status == 302
    raise "Expected pi_other position unchanged" unless pi_other.reload.position == 1

    session.patch(helpers.move_item_portfolio_path(portfolio_a), params: { item_id: pi_2.id, direction: "sideways" })
    raise "Expected 302 redirect on invalid direction" unless session.status == 302
    raise "Expected order unchanged on invalid direction" unless portfolio_a.portfolio_items.reload.to_a == [pi_1, pi_2, pi_3]
    puts "2. PortfolioController#move_item happy paths & guards passed."

    # 3. Exhibition move_item happy paths & guards
    exhibition_a = Exhibition.create!(title: "Order Exhibition A #{rand_suffix}")
    exhibition_b = Exhibition.create!(title: "Order Exhibition B #{rand_suffix}")
    created_ids[:exhibition_ids].concat([exhibition_a.id, exhibition_b.id])

    ei_1 = ExhibitionItem.create!(exhibition: exhibition_a, photo: photos[0])
    ei_2 = ExhibitionItem.create!(exhibition: exhibition_a, photo: photos[1])
    ei_3 = ExhibitionItem.create!(exhibition: exhibition_a, photo: photos[2])
    ei_other = ExhibitionItem.create!(exhibition: exhibition_b, photo: photos[0])
    created_ids[:exhibition_item_ids].concat([ei_1.id, ei_2.id, ei_3.id, ei_other.id])

    session.patch(helpers.move_item_exhibition_path(exhibition_a), params: { item_id: ei_3.id, direction: "higher" })
    raise "Expected 302 redirect on PATCH move_item_exhibition_path, got #{session.status}" unless session.status == 302
    raise "Expected exhibition_a order [ei_1, ei_3, ei_2]" unless exhibition_a.exhibition_items.reload.to_a == [ei_1, ei_3, ei_2]

    session.patch(helpers.move_item_exhibition_path(exhibition_a), params: { item_id: ei_3.id, direction: "lower" })
    raise "Expected 302 redirect on PATCH move_item_exhibition_path, got #{session.status}" unless session.status == 302
    raise "Expected exhibition_a order [ei_1, ei_2, ei_3]" unless exhibition_a.exhibition_items.reload.to_a == [ei_1, ei_2, ei_3]

    # Guarded constraint: cross-exhibition item_id
    session.patch(helpers.move_item_exhibition_path(exhibition_a), params: { item_id: ei_other.id, direction: "higher" })
    raise "Expected 302 redirect on out-of-scope exhibition item_id" unless session.status == 302
    raise "Expected ei_other position unchanged" unless ei_other.reload.position == 1
    puts "3. ExhibitionController#move_item happy paths & guards passed."

    # 4. Verify rendered DOM structure & boundary clamping in portfolio#show and exhibition#show
    session.get(helpers.portfolio_path(portfolio_a))
    raise "Expected 200 on GET /portfolio/:id, got #{session.status}" unless session.status == 200
    raise "Expected .thumb-order-bar in portfolio#show HTML" unless session.body.include?("thumb-order-bar")
    raise "Expected disabled nav-prev span on first portfolio item" unless session.body.include?("thumb-order-btn nav-prev disabled")
    raise "Expected disabled nav-next span on last portfolio item" unless session.body.include?("thumb-order-btn nav-next disabled")
    raise "Expected move_item_portfolio_path form action in portfolio#show HTML" unless session.body.include?(helpers.move_item_portfolio_path(portfolio_a))

    session.get(helpers.exhibition_path(exhibition_a))
    raise "Expected 200 on GET /exhibition/:id, got #{session.status}" unless session.status == 200
    raise "Expected .thumb-order-bar in exhibition#show HTML" unless session.body.include?("thumb-order-bar")
    raise "Expected disabled nav-prev span on first exhibition item" unless session.body.include?("thumb-order-btn nav-prev disabled")
    raise "Expected disabled nav-next span on last exhibition item" unless session.body.include?("thumb-order-btn nav-next disabled")
    raise "Expected move_item_exhibition_path form action in exhibition#show HTML" unless session.body.include?(helpers.move_item_exhibition_path(exhibition_a))
    puts "4. Rendered DOM .thumb-order-bar & boundary clamping verified in portfolio#show and exhibition#show."

    raise ActiveRecord::Rollback
  end
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
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
puts "4. Zero residual test records verified."

puts "=== All Step 2 Collection Item Ordering Controller Tests Passed ==="

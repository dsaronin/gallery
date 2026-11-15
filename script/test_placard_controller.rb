# frozen_string_literal: true

# script/test_placard_controller.rb
# Run via: bin/rails runner script/test_placard_controller.rb

require "securerandom"

puts "=== Testing PlacardController Routes, Target Resolution & CRUD Actions ==="

helpers = Rails.application.routes.url_helpers

# 1. Verify singular route generation helpers
raise "Expected placard_index_path to be /placard" unless helpers.placard_index_path == "/placard"
raise "Expected new_placard_path to be /placard/new" unless helpers.new_placard_path == "/placard/new"
raise "Expected placard_path(1) to be /placard/1" unless helpers.placard_path(1) == "/placard/1"
raise "Expected edit_placard_path(1) to be /placard/1/edit" unless helpers.edit_placard_path(1) == "/placard/1/edit"
raise "Expected itemcard_placard_path(1) to be /placard/1/itemcard" unless helpers.itemcard_placard_path(1) == "/placard/1/itemcard"
raise "Expected display_placard_path(1) to be /placard/1/display" unless helpers.display_placard_path(1) == "/placard/1/display"
puts "1. Singular Placard route helpers verified."

original_forgery_setting = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false

created_ids = {
  catalog_id: nil,
  photo_id: nil,
  exhibition_id: nil,
  exhibition_item_id: nil,
  placard_ids: []
}

begin
  ActiveRecord::Base.transaction do
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host!("localhost")
    rand_suffix = SecureRandom.hex(4)

    catalog = Catalog.create!(
      name:  "Ctrl Cat #{rand_suffix}",
      fname: "ctrl_cat_#{rand_suffix}",
      fpath: "/tmp/ctrl_cat_#{rand_suffix}"
    )
    created_ids[:catalog_id] = catalog.id

    photo = Photo.create!(
      catalog:   catalog,
      photo_dsc: "Controller Test Photo",
      filename:  "CTRL_#{rand_suffix}.NEF",
      photodate: Time.zone.parse("2025-04-10 10:00:00")
    )
    created_ids[:photo_id] = photo.id

    exhibition = Exhibition.create!(title: "Controller Exhibition #{rand_suffix}")
    created_ids[:exhibition_id] = exhibition.id

    exhibition_item = ExhibitionItem.create!(exhibition: exhibition, photo: photo)
    created_ids[:exhibition_item_id] = exhibition_item.id

    # 2. Test GET /placard (index)
    session.get(helpers.placard_index_path)
    raise "Expected 200 on GET /placard, got #{session.status}" unless session.status == 200
    puts "2. GET /placard (index) passed."

    # 3. Test GET /placard/collection_show for unpersisted Exhibition fallback
    session.get(helpers.collection_show_placard_index_path(target_type: "Exhibition", target_id: exhibition.id))
    raise "Expected 200 on GET /placard/collection_show, got #{session.status}" unless session.status == 200
    puts "3. GET /placard/collection_show (unpersisted fallback) passed."

    # 4. Test GET /placard/itemcard & GET /placard/display for unpersisted ExhibitionItem
    session.get(helpers.itemcard_placard_index_path(target_type: "ExhibitionItem", target_id: exhibition_item.id))
    raise "Expected 200 on GET /placard/itemcard, got #{session.status}" unless session.status == 200

    session.get(helpers.display_placard_index_path(target_type: "ExhibitionItem", target_id: exhibition_item.id))
    raise "Expected 200 on GET /placard/display, got #{session.status}" unless session.status == 200
    puts "4. GET /placard/itemcard & /placard/display (unpersisted ExhibitionItem) passed."

    # 5. Test POST /placard (create) linked to Exhibition
    session.post(helpers.placard_index_path, params: {
      target_type: "Exhibition",
      target_id:   exhibition.id,
      placard: {
        title:       "Exhibition Master Placard #{rand_suffix}",
        artist_name: "David S. Anderson",
        medium:      "Archival Pigment Print",
        price:       ""
      }
    })

    exhibition.reload
    raise "Expected 302 redirect after POST /placard, got #{session.status}" unless session.status == 302
    raise "Expected Exhibition#placard to be assigned after create" unless exhibition.placard.present?
    created_ids[:placard_ids] << exhibition.placard.id
    raise "Expected blank price string to normalize to nil" unless exhibition.placard.price.nil?
    puts "5. POST /placard (create & attach to Exhibition) passed."

    # 6. Test PATCH /placard/:id (update)
    placard = exhibition.placard
    session.patch(helpers.placard_path(placard), params: {
      target_type: "Exhibition",
      target_id:   exhibition.id,
      placard: {
        price:      525,
        cc_license: "cc_by_nc"
      }
    })

    placard.reload
    raise "Expected 302 redirect after PATCH /placard/:id, got #{session.status}" unless session.status == 302
    raise "Expected price to update to 525" unless placard.price == 525
    raise "Expected cc_license to update to 'cc_by_nc'" unless placard.cc_license == "cc_by_nc"
    puts "6. PATCH /placard/:id (update) passed."

    # 7. Test DELETE /placard/:id (nullifies Exhibition#placard cleanly)
    session.delete(helpers.placard_path(placard), params: {
      target_type: "Exhibition",
      target_id:   exhibition.id
    })

    exhibition.reload
    raise "Expected 302 redirect after DELETE /placard/:id, got #{session.status}" unless session.status == 302
    raise "Expected Placard ##{placard.id} to be destroyed" if Placard.exists?(placard.id)
    raise "Expected Exhibition#placard_id to be nullified" unless exhibition.placard_id.nil?
    puts "7. DELETE /placard/:id (clean nullify on owner) passed."

    # 8. Test missing record guard
    session.get(helpers.placard_path(999_999_999))
    raise "Expected 302 redirect on missing Placard, got #{session.status}" unless session.status == 302
    raise "Expected alert flash on missing Placard" if session.flash[:alert].blank?
    puts "8. Missing Placard guard passed."

    raise ActiveRecord::Rollback
  end
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
  ExhibitionItem.where(id: created_ids[:exhibition_item_id]).delete_all if created_ids[:exhibition_item_id]
  Exhibition.where(id: created_ids[:exhibition_id]).delete_all if created_ids[:exhibition_id]
  Photo.where(id: created_ids[:photo_id]).delete_all if created_ids[:photo_id]
  Catalog.where(id: created_ids[:catalog_id]).delete_all if created_ids[:catalog_id]
  Placard.where(id: created_ids[:placard_ids]).delete_all if created_ids[:placard_ids].any?
end

raise "Residual Placards detected!" if created_ids[:placard_ids].any? && Placard.where(id: created_ids[:placard_ids]).exists?
raise "Residual Exhibition detected!" if created_ids[:exhibition_id] && Exhibition.exists?(created_ids[:exhibition_id])
raise "Residual Photo detected!" if created_ids[:photo_id] && Photo.exists?(created_ids[:photo_id])
raise "Residual Catalog detected!" if created_ids[:catalog_id] && Catalog.exists?(created_ids[:catalog_id])
puts "9. Zero residual test records verified."

puts "=== All Phase 3 PlacardController & Routing Tests Passed ==="

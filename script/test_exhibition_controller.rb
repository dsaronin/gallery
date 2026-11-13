# script/test_exhibition_controller.rb
# Run via: bin/rails runner script/test_exhibition_controller.rb

require "securerandom"

puts "=== Testing ExhibitionController Routes & Actions ==="

helpers = Rails.application.routes.url_helpers

# 1. Verify route generation helpers
raise "Expected exhibition_index_path to be /exhibition" unless helpers.exhibition_index_path == "/exhibition"
raise "Expected new_exhibition_path to be /exhibition/new" unless helpers.new_exhibition_path == "/exhibition/new"
raise "Expected exhibition_path(1) to be /exhibition/1" unless helpers.exhibition_path(1) == "/exhibition/1"
raise "Expected edit_exhibition_path(1) to be /exhibition/1/edit" unless helpers.edit_exhibition_path(1) == "/exhibition/1/edit"
raise "Expected clear_items_exhibition_path(1) to be /exhibition/1/clear_items" unless helpers.clear_items_exhibition_path(1) == "/exhibition/1/clear_items"
puts "1. Route generation helpers passed."

original_forgery_setting = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false

begin
  ActiveRecord::Base.transaction do
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host!("localhost")
    rand_suffix = SecureRandom.hex(4)

    # 2. Test POST /exhibition (create)
    title = "Test Exhibition #{rand_suffix}"
    session.post(helpers.exhibition_index_path, params: {
      exhibition: {
        title: title,
        sales_policy: "direct_inquiry",
        budget: 1500
      }
    })

    exhibition = Exhibition.find_by!(title: title)
    raise "Expected redirect (302) after create, got #{session.status}" unless session.status == 302
    raise "Expected redirect to #{helpers.exhibition_path(exhibition)}" unless session.response.location.end_with?(helpers.exhibition_path(exhibition))
    raise "Expected flash notice on create" unless session.flash[:notice].to_s.include?(title)
    raise "Expected session current_exhibition_id to be #{exhibition.id}" unless session.session[:gallery_state][:current_exhibition_id] == exhibition.id
    puts "2. POST /exhibition (create) and session tracking passed."

    # 3. Test PATCH /exhibition/:id (update)
    updated_title = "#{title} Updated"
    session.patch(helpers.exhibition_path(exhibition), params: {
      exhibition: {
        title: updated_title,
        status: "scheduled",
        total_expenses: 450,
        approved_by_artist_at: Date.current.to_s
      }
    })

    exhibition.reload
    raise "Expected redirect (302) after update, got #{session.status}" unless session.status == 302
    raise "Expected title to update to '#{updated_title}'" unless exhibition.title == updated_title
    raise "Expected status to update to scheduled" unless exhibition.scheduled?
    raise "Expected total_expenses to update to 450" unless exhibition.total_expenses == 450
    puts "3. PATCH /exhibition/:id (update) passed."

    # 4. Test DELETE /exhibition/:id/clear_items
    catalog = Catalog.create!(name: "Temp Cat #{rand_suffix}", fname: "temp_cat_#{rand_suffix}", fpath: "/tmp/test")
    photo = catalog.photos.create!(
      photo_dsc: "Exhibition Shot",
      filename: "exh_#{rand_suffix}.jpg",
      photodate: Time.current,
      stars: 4
    )
    exhibition.exhibition_items.create!(photo: photo)
    exhibition.update!(curation_criteria: [Gallery::CurationCriteria.new(min_stars: 3)])

    session.delete(helpers.clear_items_exhibition_path(exhibition))
    exhibition.reload
    raise "Expected redirect (302) after clear_items, got #{session.status}" unless session.status == 302
    raise "Expected exhibition_items to be empty after clear_items" unless exhibition.exhibition_items.empty?
    raise "Expected curation_criteria to be empty after clear_items" unless exhibition.curation_criteria.empty?
    puts "4. DELETE /exhibition/:id/clear_items passed."

    # 5. Test DELETE /exhibition/:id (destroy)
    session.delete(helpers.exhibition_path(exhibition))
    raise "Expected redirect (302) after destroy, got #{session.status}" unless session.status == 302
    raise "Expected Exhibition ##{exhibition.id} to be destroyed" if Exhibition.exists?(exhibition.id)
    raise "Expected session current_exhibition_id to be nil after destroy" unless session.session[:gallery_state][:current_exhibition_id].nil?
    puts "5. DELETE /exhibition/:id (destroy) and session cleanup passed."

    # 6. Test missing record rescue
    session.get(helpers.exhibition_path(999_999_999))
    raise "Expected redirect (302) on missing Exhibition, got #{session.status}" unless session.status == 302
    raise "Expected flash alert on missing Exhibition" unless session.flash[:alert].to_s.include?("Exhibition not found")
    puts "6. Missing Exhibition rescue passed."

    raise ActiveRecord::Rollback
  end
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
end

puts "=== All ExhibitionController Tests Passed ==="

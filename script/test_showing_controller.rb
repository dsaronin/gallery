# script/test_showing_controller.rb
# Run via: bin/rails runner script/test_showing_controller.rb

require "securerandom"

puts "=== Testing ShowingController Routes, SessionState & CRUD Actions ==="

helpers = Rails.application.routes.url_helpers

# 1. Verify singular route generation helpers
raise "Expected showing_index_path to be /showing" unless helpers.showing_index_path == "/showing"
raise "Expected new_showing_path to be /showing/new" unless helpers.new_showing_path == "/showing/new"
raise "Expected showing_path(1) to be /showing/1" unless helpers.showing_path(1) == "/showing/1"
raise "Expected edit_showing_path(1) to be /showing/1/edit" unless helpers.edit_showing_path(1) == "/showing/1/edit"
puts "1. Route generation helpers passed."

original_forgery_setting = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false

begin
  ActiveRecord::Base.transaction do
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host!("localhost")
    rand_suffix = SecureRandom.hex(4)

    # 2. Test POST /showing (create independent stub) and SessionState tracking
    showing_title = "Autumn Run #{rand_suffix}"
    session.post(helpers.showing_index_path, params: {
      showing: {
        title: showing_title,
        start_date: (Date.current + 10.days).to_s,
        end_date: (Date.current + 24.days).to_s
      }
    })

    showing = Showing.find_by!(title: showing_title)
    raise "Expected redirect (302) after create, got #{session.status}" unless session.status == 302
    raise "Expected redirect to #{helpers.showing_path(showing)}" unless session.response.location.end_with?(helpers.showing_path(showing))
    raise "Expected flash notice on create" unless session.flash[:notice].to_s.include?(showing_title)
    raise "Expected default status :scheduled, got #{showing.status}" unless showing.scheduled?
    raise "Expected session current_showing_id to be #{showing.id}" unless session.session[:gallery_state][:current_showing_id] == showing.id
    puts "2. POST /showing (create stub) and SessionState tracking passed."

    # 3. Test PATCH /showing/:id (update) with extended edit fields & associations
    venue = Venue.create!(name: "Controller Test Venue #{rand_suffix}")
    exhibition = Exhibition.create!(title: "Controller Test Exhibition #{rand_suffix}")
    updated_title = "#{showing_title} Updated"

    session.patch(helpers.showing_path(showing), params: {
      showing: {
        title: updated_title,
        status: "in_progress",
        venue_id: venue.id,
        exhibition_id: exhibition.id,
        prep_days: 2,
        teardown_days: 2,
        rental_cost: 450,
        reception_date: (Time.current + 12.days).strftime("%Y-%m-%dT%H:%M"),
        visitation_count: 85,
        notes: "Opening reception confirmed."
      }
    })

    showing.reload
    raise "Expected redirect (302) after update, got #{session.status}" unless session.status == 302
    raise "Expected title to update to '#{updated_title}'" unless showing.title == updated_title
    raise "Expected status to update to :in_progress" unless showing.in_progress?
    raise "Expected venue_id to update to #{venue.id}" unless showing.venue_id == venue.id
    raise "Expected exhibition_id to update to #{exhibition.id}" unless showing.exhibition_id == exhibition.id
    raise "Expected prep_days to update to 2" unless showing.prep_days == 2
    raise "Expected rental_cost to update to 450" unless showing.rental_cost == 450
    raise "Expected visitation_count to update to 85" unless showing.visitation_count == 85
    puts "3. PATCH /showing/:id (update) passed."

    # 4. Test guarded DELETE /showing/:id while associated with an Exhibition
    session.delete(helpers.showing_path(showing))
    raise "Expected redirect (302) on guarded delete, got #{session.status}" unless session.status == 302
    raise "Expected flash alert on guarded delete" unless session.flash[:alert].to_s.downcase.include?("exhibition")
    raise "Expected exhibition-linked Showing ##{showing.id} NOT to be destroyed" unless Showing.exists?(showing.id)
    puts "4. Guarded DELETE /showing/:id (Exhibition association preserved) passed."

    # 5. Test clean DELETE /showing/:id once unassociated from Exhibition
    showing.update!(exhibition_id: nil)
    session.delete(helpers.showing_path(showing))
    raise "Expected redirect (302) after destroy, got #{session.status}" unless session.status == 302
    raise "Expected Showing ##{showing.id} to be destroyed" if Showing.exists?(showing.id)
    raise "Expected session current_showing_id to be nil after destroy" unless session.session[:gallery_state][:current_showing_id].nil?
    puts "5. Clean DELETE /showing/:id and SessionState cleanup passed."

    # 6. Test missing record rescue
    session.get(helpers.showing_path(999_999_999))
    raise "Expected redirect (302) on missing Showing, got #{session.status}" unless session.status == 302
    raise "Expected flash alert on missing Showing" unless session.flash[:alert].to_s.include?("Showing not found")
    puts "6. Missing Showing rescue passed."

    raise ActiveRecord::Rollback
  end
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
end

puts "=== All Step 2 ShowingController Tests Passed ==="

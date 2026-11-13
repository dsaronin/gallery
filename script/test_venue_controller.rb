# script/test_venue_controller.rb
# Run via: bin/rails runner script/test_venue_controller.rb

require "securerandom"

puts "=== Testing VenueController Routes, SessionState & CRUD Actions ==="

helpers = Rails.application.routes.url_helpers

# 1. Verify singular route generation helpers
raise "Expected venue_index_path to be /venue" unless helpers.venue_index_path == "/venue"
raise "Expected new_venue_path to be /venue/new" unless helpers.new_venue_path == "/venue/new"
raise "Expected venue_path(1) to be /venue/1" unless helpers.venue_path(1) == "/venue/1"
raise "Expected edit_venue_path(1) to be /venue/1/edit" unless helpers.edit_venue_path(1) == "/venue/1/edit"
puts "1. Route generation helpers passed."

original_forgery_setting = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false

begin
  ActiveRecord::Base.transaction do
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host!("localhost")
    rand_suffix = SecureRandom.hex(4)

    # 2. Test POST /venue (create) and SessionState tracking
    venue_name = "Test Gallery #{rand_suffix}"
    session.post(helpers.venue_index_path, params: {
      venue: {
        name: venue_name,
        venue_type: "commercial_gallery",
        space_name: "North Room",
        wall_linear_meters: 24,
        rate_per_day: 150,
        address: "450 Broadway, Oakland, CA"
      }
    })

    venue = Venue.find_by!(name: venue_name)
    raise "Expected redirect (302) after create, got #{session.status}" unless session.status == 302
    raise "Expected redirect to #{helpers.venue_path(venue)}" unless session.response.location.end_with?(helpers.venue_path(venue))
    raise "Expected flash notice on create" unless session.flash[:notice].to_s.include?(venue_name)
    raise "Expected default status :pending, got #{venue.status}" unless venue.pending?
    raise "Expected session current_venue_id to be #{venue.id}" unless session.session[:gallery_state][:current_venue_id] == venue.id
    puts "2. POST /venue (create) and SessionState tracking passed."

    # 3. Test PATCH /venue/:id (update) with extended edit fields
    updated_name = "#{venue_name} Updated"
    session.patch(helpers.venue_path(venue), params: {
      venue: {
        name: updated_name,
        status: "booked",
        contact_name: "Amina Mussa",
        contact_position: "Curator",
        contact_email: "amina@example.org",
        contact_phone: "+1-510-555-0199",
        website_url: "https://example.org",
        notes: "Track lighting installed."
      }
    })

    venue.reload
    raise "Expected redirect (302) after update, got #{session.status}" unless session.status == 302
    raise "Expected name to update to '#{updated_name}'" unless venue.name == updated_name
    raise "Expected status to update to :booked" unless venue.booked?
    raise "Expected contact_name to update" unless venue.contact_name == "Amina Mussa"
    puts "3. PATCH /venue/:id (update) passed."

    # 4. Test guarded DELETE /venue/:id when status is :booked
    session.delete(helpers.venue_path(venue))
    raise "Expected redirect (302) on blocked delete, got #{session.status}" unless session.status == 302
    raise "Expected flash alert on blocked delete" unless session.flash[:alert].to_s.include?("Booked")
    raise "Expected booked Venue ##{venue.id} NOT to be destroyed" unless Venue.exists?(venue.id)
    puts "4. Guarded DELETE /venue/:id (status :booked preserved) passed."

    # 5. Test guarded DELETE /venue/:id when associated with an Exhibition
    venue.update!(status: :pending)
    exhibition = Exhibition.create!(title: "Venue Guard Exhibition #{rand_suffix}", venue: venue)

    session.delete(helpers.venue_path(venue))
    raise "Expected redirect (302) on association-blocked delete, got #{session.status}" unless session.status == 302
    raise "Expected flash alert on association-blocked delete" if session.flash[:alert].blank?
    raise "Expected exhibition-linked Venue ##{venue.id} NOT to be destroyed" unless Venue.exists?(venue.id)
    puts "5. Guarded DELETE /venue/:id (Exhibition association preserved) passed."

    # 6. Test clean DELETE /venue/:id once unassociated and :pending
    exhibition.destroy!
    session.delete(helpers.venue_path(venue))
    raise "Expected redirect (302) after destroy, got #{session.status}" unless session.status == 302
    raise "Expected Venue ##{venue.id} to be destroyed" if Venue.exists?(venue.id)
    raise "Expected session current_venue_id to be nil after destroy" unless session.session[:gallery_state][:current_venue_id].nil?
    puts "6. Clean DELETE /venue/:id and SessionState cleanup passed."

    # 7. Test missing record rescue
    session.get(helpers.venue_path(999_999_999))
    raise "Expected redirect (302) on missing Venue, got #{session.status}" unless session.status == 302
    raise "Expected flash alert on missing Venue" unless session.flash[:alert].to_s.include?("Venue not found")
    puts "7. Missing Venue rescue passed."

    raise ActiveRecord::Rollback
  end
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
end

puts "=== All Step 1.2 VenueController Tests Passed ==="

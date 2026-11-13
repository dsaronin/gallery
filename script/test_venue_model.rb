# script/test_venue_model.rb
# Run via: bin/rails runner script/test_venue_model.rb

require "securerandom"

puts "=== Testing Venue Model, Enums, Seeding & Guarded Destroy ==="

# 1. Verify dictionary constants
expected_statuses = { mock: 0, pending: 1, booked: 2, showing: 3, archived: 4 }
raise "Expected VENUE_STATUSES to match #{expected_statuses}" unless Gallery::Environ::VENUE_STATUSES == expected_statuses
puts "1. Gallery::Environ::VENUE_STATUSES verified."

# 2. Verify seeded Abstract Mock Venue
mock_venue = Venue.find_by(name: "Mock Gallery")
raise "Expected seeded 'Mock Gallery' to exist" unless mock_venue
raise "Expected seeded mock venue status to be :mock, got #{mock_venue.status}" unless mock_venue.mock?
raise "Expected seeded mock venue type to be :commercial_gallery" unless mock_venue.commercial_gallery?
puts "2. Seeded 'Standard Mock Gallery' verified (ID: #{mock_venue.id}, wall: #{mock_venue.wall_linear_meters}m)."

ActiveRecord::Base.transaction do
  rand_suffix = SecureRandom.hex(4)

  # 3. Verify default attributes on new Venue
  fresh = Venue.new(name: "Proposed Space #{rand_suffix}")
  raise "Expected default status :pending, got #{fresh.status}" unless fresh.pending?
  raise "Expected default venue_type :commercial_gallery, got #{fresh.venue_type}" unless fresh.commercial_gallery?
  fresh.save!
  puts "3. Default Venue enum values verified."

  # 4. Verify status-based guarded deletion (:booked, :showing, :archived blocked)
  %i[booked showing archived].each do |locked_status|
    fresh.update!(status: locked_status)
    raise "Expected deletable? to be false for #{locked_status}" if fresh.deletable?
    raise "Expected destroy to fail for #{locked_status}" if fresh.destroy
    raise "Expected error message mentioning #{locked_status.to_s.humanize}" unless fresh.errors.full_messages.to_sentence.include?(locked_status.to_s.humanize)
  end
  puts "4. Protected status destroy guards (:booked, :showing, :archived) verified."

  # 5. Verify association-based guarded deletion (:pending with Exhibition blocked)
  fresh.update!(status: :pending)
  raise "Expected deletable? to be true when pending with no associations" unless fresh.deletable?

  exhibition = Exhibition.create!(title: "Guard Exhibition #{rand_suffix}", venue: fresh)
  raise "Expected deletable? to be false when referenced by Exhibition" if fresh.deletable?
  raise "Expected destroy to fail when referenced by Exhibition" if fresh.destroy
  puts "5. Association destroy guard (Exhibition reference) verified."

  # 6. Verify destroy succeeds once association is removed and status is :pending
  exhibition.destroy!
  raise "Expected destroy to succeed on unassociated :pending venue" unless fresh.destroy
  raise "Expected Venue ##{fresh.id} to be removed" if Venue.exists?(fresh.id)
  puts "6. Clean destroy of unassociated :pending venue verified."

  raise ActiveRecord::Rollback
end

puts "=== All Step 1.1 Venue Model Tests Passed ==="

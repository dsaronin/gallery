# script/test_showing_model.rb
# Run via: bin/rails runner script/test_showing_model.rb

require "securerandom"

puts "=== Testing Showing Model, Enums, Seeding & Guarded Destroy ==="

# 1. Verify dictionary constants
expected_statuses = { scheduled: 0, in_progress: 1, completed: 2, canceled: 3 }
raise "Expected SHOWING_STATUSES to match #{expected_statuses}" unless Gallery::Environ::SHOWING_STATUSES == expected_statuses
puts "1. Gallery::Environ::SHOWING_STATUSES verified."

# 2. Verify seeded Mock Showing
mock_showing = Showing.find_by(title: "Mock Exhibition Run")
raise "Expected seeded 'Mock Exhibition Run' to exist" unless mock_showing
raise "Expected seeded mock showing status to be :scheduled, got #{mock_showing.status}" unless mock_showing.scheduled?
raise "Expected seeded mock showing to be deletable (no exhibition)" unless mock_showing.deletable?
puts "2. Seeded 'Mock Exhibition Run' verified (ID: #{mock_showing.id}, venue: #{mock_showing.venue&.name || 'None'})."

ActiveRecord::Base.transaction do
  rand_suffix = SecureRandom.hex(4)

  # 3. Verify independent stub creation without Exhibition or Venue
  stub = Showing.new(
    title: "Standalone Run #{rand_suffix}",
    start_date: Date.current + 14.days,
    end_date: Date.current + 28.days
  )
  raise "Expected default status :scheduled, got #{stub.status}" unless stub.scheduled?
  raise "Expected default prep_days 1, got #{stub.prep_days}" unless stub.prep_days == 1
  raise "Expected default teardown_days 1, got #{stub.teardown_days}" unless stub.teardown_days == 1
  stub.save!
  raise "Expected unassociated stub to be deletable?" unless stub.deletable?
  puts "3. Independent Showing stub creation and defaults verified."

  # 4. Verify DateRangeValidatable enforcement (end_date < start_date rejected)
  invalid_dates = Showing.new(
    title: "Invalid Dates #{rand_suffix}",
    start_date: Date.current + 10.days,
    end_date: Date.current + 5.days
  )
  raise "Expected end_date < start_date to be invalid" if invalid_dates.valid?
  puts "4. DateRangeValidatable constraint verified."

  # 5. Verify guarded deletion when associated with an Exhibition
  exhibition = Exhibition.create!(title: "Guard Exhibition #{rand_suffix}")
  stub.update!(exhibition: exhibition)
  raise "Expected deletable? to be false when linked to Exhibition" if stub.deletable?
  raise "Expected direct destroy to fail when linked to Exhibition" if stub.destroy
  raise "Expected error message mentioning exhibition" unless stub.errors.full_messages.to_sentence.downcase.include?("exhibition")
  puts "5. Guarded direct destroy while associated with Exhibition verified."

  # 6. Verify cascade destroy when parent Exhibition is destroyed
  exhibition.update!(showing: stub)
  exhibition.destroy!
  raise "Expected Showing ##{stub.id} to be destroyed via Exhibition cascade" if Showing.exists?(stub.id)
  puts "6. Cascade destroy upon parent Exhibition deletion verified."

  # 7. Verify clean direct destroy of unassociated Showing
  standalone = Showing.create!(
    title: "Clean Destroy Run #{rand_suffix}",
    start_date: Date.current + 30.days,
    end_date: Date.current + 40.days
  )
  raise "Expected direct destroy to succeed for unassociated Showing" unless standalone.destroy
  raise "Expected Showing ##{standalone.id} to be removed" if Showing.exists?(standalone.id)
  puts "7. Clean direct destroy of unassociated Showing verified."

  raise ActiveRecord::Rollback
end

puts "=== All Step 1 Showing Model Tests Passed ==="

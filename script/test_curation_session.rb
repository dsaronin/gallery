# frozen_string_literal: true

require_relative '../config/environment'

puts "\n=== RUNNING CURATION SESSION STATE TESTS ==="

# 1. Setup mock session and test objects
mock_session = {}
portfolio = Portfolio.first || Portfolio.create!(title: "Test Portfolio", status: :curating)
criteria_params = {
  sources: { catalog_ids: [1, 2] },
  min_stars: 4,
  tag_ids: [10]
}
criteria = Gallery::CurationCriteria.new(criteria_params)

# 2. Initialize SessionState and stage criteria
state = Gallery::Environ::SessionState.load(mock_session)
state.stage_criteria!(portfolio, criteria)
state.persist!(mock_session)

# Verify mock_session holds serialized data
raw_key = "portfolio_#{portfolio.id}"
stored_data = mock_session.dig(Gallery::Environ::SessionState::SESSION_KEY, :staged_curations, raw_key)

if stored_data && stored_data.dig(:sources, :catalog_ids) == [1, 2]
  puts " [PASS] Staging and session persistence succeeded"
else
  puts " [FAIL] Failed to persist staged criteria into mock session"
  puts "        Actual: #{mock_session.inspect}"
  exit 1
end

# 3. Simulate subsequent request: hydrate fresh SessionState from session
fresh_state = Gallery::Environ::SessionState.load(mock_session)
restored_criteria = fresh_state.staged_criteria_for(portfolio)

if restored_criteria.is_a?(Gallery::CurationCriteria) &&
   restored_criteria.catalog_ids == [1, 2] &&
   restored_criteria.min_stars == 4
  puts " [PASS] Hydration and round-trip CurationCriteria reconstruction succeeded"
else
  puts " [FAIL] Hydrated criteria mismatch"
  puts "        Actual: #{restored_criteria.inspect}"
  exit 1
end

# 4. Test clearance
fresh_state.clear_staged_criteria!(portfolio)
fresh_state.persist!(mock_session)

cleared_state = Gallery::Environ::SessionState.load(mock_session)
blank_criteria = cleared_state.staged_criteria_for(portfolio)

if blank_criteria.empty? && !blank_criteria.active?
  puts " [PASS] Curation staging clearance succeeded"
else
  puts " [FAIL] Criteria was not cleared from session"
  puts "        Actual: #{blank_criteria.inspect}"
  exit 1
end

puts "\nALL CURATION SESSION TESTS PASSED.\n\n"

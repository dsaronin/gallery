# frozen_string_literal: true

# Usage: bin/rails runner script/test_curation_criteria.rb

require_relative '../lib/gallery/curation_criteria'

puts "==> Starting validation for Gallery::CurationCriteria..."

# 1. Empty initialization
empty_crit = Gallery::CurationCriteria.new
raise "Assertion failed: expected empty? to be true" unless empty_crit.empty?
raise "Assertion failed: expected active? to be false" if empty_crit.active?
puts "  [PASS] Empty criteria defaults correctly."

# 2. String/form input coercion & sanitization
form_payload = {
  "sources" => {
    "catalog_ids" => ["1", "", "4", "1"],
    "portfolio_ids" => ["2"],
    "exhibition_ids" => []
  },
  "tag_ids" => ["12", "18", "12"],
  "talent_ids" => ["3"],
  "min_stars" => "3",
  "exact_stars" => "",
  "date_range" => {
    "start_date" => "2026-05-01",
    "end_date" => "2026-10-31"
  }
}

crit = Gallery::CurationCriteria.new(form_payload)
raise "Assertion failed: catalog_ids should be [1, 4]" unless crit.catalog_ids == [1, 4]
raise "Assertion failed: portfolio_ids should be [2]" unless crit.portfolio_ids == [2]
raise "Assertion failed: exhibition_ids should be []" unless crit.exhibition_ids == []
raise "Assertion failed: tag_ids should be [12, 18]" unless crit.tag_ids == [12, 18]
raise "Assertion failed: talent_ids should be [3]" unless crit.talent_ids == [3]
raise "Assertion failed: min_stars should be 3" unless crit.min_stars == 3
raise "Assertion failed: exact_stars should be nil" unless crit.exact_stars.nil?
raise "Assertion failed: start_date should be Date" unless crit.start_date == Date.new(2026, 5, 1)
raise "Assertion failed: end_date should be Date" unless crit.end_date == Date.new(2026, 10, 31)
raise "Assertion failed: active? should be true" unless crit.active?
puts "  [PASS] Form parameter normalization, casting, and deduplication passed."

# 3. Serialization to JSON and round-trip restore
json_str = crit.to_json
restored = Gallery::CurationCriteria.load(json_str)
raise "Assertion failed: restored catalog_ids mismatch" unless restored.catalog_ids == [1, 4]
raise "Assertion failed: restored min_stars mismatch" unless restored.min_stars == 3
raise "Assertion failed: restored start_date mismatch" unless restored.start_date == Date.new(2026, 5, 1)
puts "  [PASS] JSON dump and load round-trip succeeded."

# 4. Star rating boundary checks (-1 reject through 5 stars)
reject_crit = Gallery::CurationCriteria.new(exact_stars: "-1", min_stars: "99")
raise "Assertion failed: exact_stars should accept -1" unless reject_crit.exact_stars == -1
raise "Assertion failed: min_stars out of range should be nil" unless reject_crit.min_stars.nil?
puts "  [PASS] Rating boundaries (-1..5) enforced."

puts "==> All Gallery::CurationCriteria checks passed successfully!"

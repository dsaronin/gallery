# frozen_string_literal: true

# Usage: bin/rails runner script/test_portfolio_criteria.rb

puts "==> Starting validation for Portfolio curation criteria integration..."

# 1. Instantiation and default criteria
portfolio = Portfolio.new(name: "test_curation_tmp", title: "Temporary Curation Test")
raise "Assertion failed: curation_criteria should default to CurationCriteria" unless portfolio.curation_criteria.is_a?(Gallery::CurationCriteria)
raise "Assertion failed: candidate_photos on empty criteria must be empty" unless portfolio.candidate_photos.empty?
puts "  [PASS] Portfolio defaults with valid empty criteria object."

# 2. Criteria assignment and persistence round-trip
payload = {
  sources: { catalog_ids: [1] },
  min_stars: 3,
  date_range: { start_date: "2026-01-01", end_date: "2026-12-31" }
}

portfolio.curation_criteria = payload
portfolio.save!

reloaded = Portfolio.find(portfolio.id)
raise "Assertion failed: reloaded criteria should be CurationCriteria" unless reloaded.curation_criteria.is_a?(Gallery::CurationCriteria)
raise "Assertion failed: catalog_ids mismatch after reload" unless reloaded.curation_criteria.catalog_ids == [1]
raise "Assertion failed: min_stars mismatch after reload" unless reloaded.curation_criteria.min_stars == 3
puts "  [PASS] Curation criteria serialized, stored in DB, and restored cleanly."

# 3. Candidate query generation from persisted portfolio
scope = reloaded.candidate_photos
raise "Assertion failed: candidate_photos must produce ActiveRecord::Relation" unless scope.respond_to?(:to_sql)
raise "Assertion failed: candidate_photos SQL must reflect criteria" unless scope.to_sql.include?("catalog_id")
puts "  [PASS] reloaded.candidate_photos generated SQL: #{scope.to_sql}"

# Clean up temporary test record
portfolio.destroy!
puts "  [PASS] Cleanup completed."

puts "==> All Portfolio curation criteria integrations passed successfully!"

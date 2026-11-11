# frozen_string_literal: true

# Usage: bin/rails runner script/test_portfolio_criteria.rb

puts "==> Starting validation for Portfolio curation criteria integration..."

# 1. Instantiation and default audit state
portfolio = Portfolio.new(name: "test_curation_tmp", title: "Temporary Curation Test", status: :draft)
raise "Assertion failed: curation_criteria should default to an Array" unless portfolio.curation_criteria.is_a?(Array)
raise "Assertion failed: default curation_criteria should be empty" unless portfolio.curation_criteria.empty?
raise "Assertion failed: candidate_photos on empty criteria must be empty" unless portfolio.candidate_photos.empty?
puts "  [PASS] Portfolio defaults with valid empty audit log array."

# 2. Criteria ingestion and persistence round-trip via curate_photos!
portfolio.save!

payload = {
  sources: { catalog_ids: [1] },
  min_stars: 3,
  date_range: { start_date: "2026-01-01", end_date: "2026-12-31" }
}

criteria = Gallery::CurationCriteria.new(payload)
portfolio.curate_photos!(criteria)

reloaded = Portfolio.find(portfolio.id)
raise "Assertion failed: reloaded criteria should be an Array" unless reloaded.curation_criteria.is_a?(Array)
raise "Assertion failed: reloaded criteria array should have 1 entry" unless reloaded.curation_criteria.size == 1

first_entry = reloaded.curation_criteria.first
raise "Assertion failed: audit log entry must be CurationCriteria" unless first_entry.is_a?(Gallery::CurationCriteria)
raise "Assertion failed: catalog_ids mismatch after reload" unless first_entry.catalog_ids == [1]
raise "Assertion failed: min_stars mismatch after reload" unless first_entry.min_stars == 3
puts "  [PASS] Curation criteria ingested into audit log, stored in DB, and restored cleanly."

# 3. Candidate query generation from persisted portfolio
scope = reloaded.candidate_photos
raise "Assertion failed: candidate_photos must produce ActiveRecord::Relation" unless scope.respond_to?(:to_sql)
raise "Assertion failed: candidate_photos SQL must reflect criteria" unless scope.to_sql.include?("catalog_id")
puts "  [PASS] reloaded.candidate_photos generated SQL: #{scope.to_sql}"

# Clean up temporary test record
portfolio.portfolio_items.destroy_all
portfolio.destroy!
puts "  [PASS] Cleanup completed."

puts "==> All Portfolio curation criteria integrations passed successfully!"

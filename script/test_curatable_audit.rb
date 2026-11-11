# frozen_string_literal: true

require_relative '../config/environment'

puts "\n=== RUNNING CURATABLE AUDIT & INGESTION TESTS ==="

portfolio = Portfolio.create!(title: "Audit Test Portfolio", status: :draft)

# 1. Ingest batch 1
criteria_1 = Gallery::CurationCriteria.new(min_stars: 3)
added_1 = portfolio.curate_photos!(criteria_1, limit: 5)
portfolio.reload

if portfolio.curation_criteria.is_a?(Array) && portfolio.curation_criteria.size == 1
  puts " [PASS] Ingestion 1 appended first criteria snapshot (Items added: #{added_1})"
else
  puts " [FAIL] Ingestion 1 failed to initialize criteria history array"
  puts "        Actual: #{portfolio.curation_criteria.inspect}"
  portfolio.destroy
  exit 1
end

# 2. Ingest batch 2 (cumulative append)
criteria_2 = Gallery::CurationCriteria.new(min_stars: 4)
added_2 = portfolio.curate_photos!(criteria_2, limit: 5)
portfolio.reload

if portfolio.curation_criteria.is_a?(Array) && 
   portfolio.curation_criteria.size == 2 &&
   portfolio.curation_criteria[0].min_stars == 3 &&
   portfolio.curation_criteria[1].min_stars == 4
  puts " [PASS] Ingestion 2 appended second criteria snapshot (Items added: #{added_2})"
else
  puts " [FAIL] Ingestion 2 failed to append to criteria history array"
  puts "        Actual: #{portfolio.curation_criteria.inspect}"
  portfolio.destroy
  exit 1
end

# 3. Clean up test record
portfolio.portfolio_items.destroy_all
portfolio.destroy
puts " [PASS] Test portfolio cleanup complete"

puts "\nALL CURATABLE AUDIT TESTS PASSED.\n\n"

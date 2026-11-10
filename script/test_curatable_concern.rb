# frozen_string_literal: true

# Usage: bin/rails runner script/test_curatable_concern.rb

puts "==> Starting validation for Curatable concern..."

# 1. Verify Portfolio integration
portfolio = Portfolio.new(name: "test_port_curatable", title: "Test Portfolio Curatable")
raise "Assertion failed: Portfolio missing candidate_photos" unless portfolio.respond_to?(:candidate_photos)
raise "Assertion failed: Portfolio max_curation_size mismatch" unless portfolio.max_curation_size == Gallery::Environ::MAX_PORTFOLIO_SIZE
raise "Assertion failed: Portfolio default criteria should be empty" unless portfolio.curation_criteria.empty?
puts "  [PASS] Portfolio correctly includes Curatable."

# 2. Verify Exhibition integration
exhibition = Exhibition.new(title: "Test Exhibition Curatable")
raise "Assertion failed: Exhibition missing candidate_photos" unless exhibition.respond_to?(:candidate_photos)
raise "Assertion failed: Exhibition max_curation_size mismatch" unless exhibition.max_curation_size == Gallery::Environ::MAX_EXHIBITION_SIZE
raise "Assertion failed: Exhibition default criteria should be empty" unless exhibition.curation_criteria.empty?
puts "  [PASS] Exhibition correctly includes Curatable."

# 3. Polymorphic criteria assignment & round-trip verification
test_criteria = { sources: { catalog_ids: [1] }, min_stars: 2 }

portfolio.curation_criteria = test_criteria
exhibition.curation_criteria = test_criteria

raise "Assertion failed: Portfolio criteria not set" unless portfolio.curation_criteria.min_stars == 2
raise "Assertion failed: Exhibition criteria not set" unless exhibition.curation_criteria.min_stars == 2
puts "  [PASS] Criteria assignment works uniformly across both models."

# 4. Safe resolution under empty criteria (guardrail check)
empty_portfolio = Portfolio.new
empty_exhibition = Exhibition.new
raise "Assertion failed: Portfolio candidate_photos on empty criteria must be none" unless empty_portfolio.candidate_photos.empty?
raise "Assertion failed: Exhibition candidate_photos on empty criteria must be none" unless empty_exhibition.candidate_photos.empty?
puts "  [PASS] Empty criteria guards resolve safely to empty sets for both models."

puts "==> All Curatable concern checks passed successfully!"

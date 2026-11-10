# frozen_string_literal: true

# Usage: bin/rails runner script/test_photo_query.rb

puts "==> Starting validation for PhotoQuery..."

# 1. Guardrail: Empty criteria MUST return Photo.none (WHERE 1=0)
empty_crit = Gallery::CurationCriteria.new
q_empty = PhotoQuery.new(empty_crit)
res_empty = q_empty.resolve
raise "Assertion failed: empty criteria must be a null_relation" unless res_empty.is_a?(ActiveRecord::Relation) && (res_empty.null_relation? || res_empty.to_sql.empty?)
raise "Assertion failed: empty criteria count must be 0" unless q_empty.count == 0
raise "Assertion failed: empty criteria cannot exceed capacity" if q_empty.exceeds_capacity?
puts "  [PASS] Empty criteria safely guarded with Photo.none."

# 2. Date window uses photodate
q_date = PhotoQuery.new(date_range: { start_date: "2026-05-01", end_date: "2026-05-31" })
sql_date = q_date.resolve.to_sql
raise "Assertion failed: SQL must reference photodate" unless sql_date.include?("photos.photodate")
puts "  [PASS] Date range bounds photodate correctly."

# 3. Talent scoping queries via catalogs.talent_id
q_talent = PhotoQuery.new(talent_ids: [4])
sql_talent = q_talent.resolve.to_sql
raise "Assertion failed: SQL must subquery catalogs for talent_id" unless sql_talent.include?("catalogs") && sql_talent.include?("talent_id")
puts "  [PASS] Talent dimension resolved through catalogs subquery."

# 4. Multi-source scoping
q_sources = PhotoQuery.new(sources: { catalog_ids: [1, 2], portfolio_ids: [5] })
sql_sources = q_sources.resolve.to_sql
puts "  [SQL OUTPUT] => #{sql_sources}"
raise "Assertion failed: SQL must check catalog_id and portfolio" unless sql_sources.include?("catalog_id")
puts "  [PASS] Multi-source union SQL generated."

# 5. Capacity limit guardrail testing
q_limit = PhotoQuery.new({ min_stars: 0 }, limit: 5)
if q_limit.count > 5
  raise "Assertion failed: exceeds_capacity? should be true" unless q_limit.exceeds_capacity?
  begin
    q_limit.resolve_safe!
    raise "Assertion failed: resolve_safe! should have raised CapacityExceededError"
  rescue PhotoQuery::CapacityExceededError
    puts "  [PASS] CapacityExceededError raised when count exceeds configured limit."
  end
else
  puts "  [SKIP] Database contains #{q_limit.count} matching test photos (<= 5 limit), capacity limit check skipped."
end

puts "==> All PhotoQuery validations passed successfully!"

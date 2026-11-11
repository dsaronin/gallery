# frozen_string_literal: true

require_relative '../config/environment'

puts "\n=== RUNNING CURATION CRITERIA CODER TESTS ==="

# 1. Instantiate sample criteria value objects
c1 = Gallery::CurationCriteria.new(sources: { catalog_ids: [1] }, min_stars: 4)
c2 = Gallery::CurationCriteria.new(sources: { catalog_ids: [2] }, min_stars: 5)

# 2. Test single object round-trip
dumped_single = Gallery::CurationCriteria.dump(c1)
loaded_single = Gallery::CurationCriteria.load(dumped_single)

if loaded_single.is_a?(Gallery::CurationCriteria) &&
   loaded_single.catalog_ids == [1] &&
   loaded_single.min_stars == 4
  puts " [PASS] Single CurationCriteria dump & load round-trip succeeded"
else
  puts " [FAIL] Single CurationCriteria round-trip failed"
  puts "        Actual: #{loaded_single.inspect}"
  exit 1
end

# 3. Test array of criteria round-trip
dumped_array = Gallery::CurationCriteria.dump([c1, c2])
loaded_array = Gallery::CurationCriteria.load(dumped_array)

if loaded_array.is_a?(Array) &&
   loaded_array.size == 2 &&
   loaded_array[0].is_a?(Gallery::CurationCriteria) &&
   loaded_array[0].catalog_ids == [1] &&
   loaded_array[1].catalog_ids == [2] &&
   loaded_array[1].min_stars == 5
  puts " [PASS] Array of CurationCriteria dump & load round-trip succeeded"
else
  puts " [FAIL] Array of CurationCriteria round-trip failed"
  puts "        Actual: #{loaded_array.inspect}"
  exit 1
end

# 4. Test edge cases (nil, blank string, empty array)
dumped_nil   = Gallery::CurationCriteria.dump(nil)
loaded_nil   = Gallery::CurationCriteria.load(dumped_nil)
loaded_blank = Gallery::CurationCriteria.load("")
dumped_empty = Gallery::CurationCriteria.dump([])
loaded_empty = Gallery::CurationCriteria.load(dumped_empty)

if dumped_nil.nil? && loaded_nil == [] && loaded_blank == [] && loaded_empty == []
  puts " [PASS] Nil, blank, and empty collection edge cases handled cleanly"
else
  puts " [FAIL] Edge case mismatch"
  puts "        dumped_nil: #{dumped_nil.inspect}"
  puts "        loaded_nil: #{loaded_nil.inspect}"
  puts "        loaded_blank: #{loaded_blank.inspect}"
  puts "        loaded_empty: #{loaded_empty.inspect}"
  exit 1
end

puts "\nALL CURATION CRITERIA CODER TESTS PASSED.\n\n"

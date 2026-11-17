# frozen_string_literal: true
# script/test_gallery_subpath_validation.rb
# Run via: bin/rails runner script/test_gallery_subpath_validation.rb

puts "=== Testing CatalogHelper#valid_downward_subpath? ==="

helper = Object.new.extend(CatalogHelper)
base_dir = "/tmp/gallery_test_base/darktable_exported"

# 1. Happy Path: Valid downward relative subpaths
valid_cases = [
  "lrg",
  "small",
  "2026/lrg",
  "export_v2/final/print",
  "  lrg  ",
  ".hidden_sub",
  "sub.dir/v1.0"
]

valid_cases.each do |subpath|
  unless helper.valid_downward_subpath?(subpath)
    raise "Expected '#{subpath.inspect}' to be valid without base_dir"
  end
  unless helper.valid_downward_subpath?(subpath, base_dir)
    raise "Expected '#{subpath.inspect}' to be valid with base_dir"
  end
end
puts "1. Valid downward subpaths (#{valid_cases.size} cases) passed."

# 2. Guarded Constraints: Invalid / traversal / malformed subpaths
invalid_cases = [
  nil,
  "",
  "   ",
  ".",
  "..",
  "/lrg",
  "/etc/passwd",
  "lrg/",
  "../sibling",
  "lrg/..",
  "lrg/../sibling",
  "lrg/../../outside",
  "./lrg",
  "lrg/./sub",
  "lrg//sub",
  "lrg\\sub",
  "lrg\0sub"
]

invalid_cases.each do |subpath|
  if helper.valid_downward_subpath?(subpath)
    raise "Expected #{subpath.inspect} to be REJECTED without base_dir"
  end
  if helper.valid_downward_subpath?(subpath, base_dir)
    raise "Expected #{subpath.inspect} to be REJECTED with base_dir"
  end
end
puts "2. Guarded constraint rejections (#{invalid_cases.size} cases) passed."

puts "=== All CatalogHelper#valid_downward_subpath? Tests Passed ==="

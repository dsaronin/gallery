# frozen_string_literal: true
# script/test_gallery_dotfile_reader.rb
# Run via: bin/rails runner script/test_gallery_dotfile_reader.rb

require "tmpdir"
require "fileutils"

puts "=== Testing CatalogHelper#read_gallery_subpath & resolve_catalog_dirpath ==="

raise "Expected Gallery::Environ.instance.photo_dotfile == '.gallery'" unless Gallery::Environ.instance.photo_dotfile == ".gallery"
raise "Expected Rails.configuration.photo_dotfile == '.gallery'" unless Rails.configuration.photo_dotfile == ".gallery"

helper = Object.new.extend(CatalogHelper)
orig_photo_path    = Rails.configuration.photo_path
orig_photo_base    = Rails.configuration.photo_base
orig_photo_source  = Rails.configuration.photo_source
orig_photo_dotfile = Rails.configuration.photo_dotfile
tmpdir = Dir.mktmpdir("gallery_dotfile_reader_test_")

begin
  Rails.configuration.photo_path    = tmpdir
  Rails.configuration.photo_base    = "Pictures"
  Rails.configuration.photo_source  = "darktable_exported"
  Rails.configuration.photo_dotfile = ".gallery"

  # 1. No .gallery file -> falls back cleanly with nil warning
  cat1_base = File.join(tmpdir, "Pictures", "Shoot_NoDotfile", "darktable_exported")
  FileUtils.mkdir_p(cat1_base)

  res1 = helper.read_gallery_subpath(cat1_base)
  raise "Expected nil subpath when .gallery absent, got #{res1.inspect}" unless res1 == { subpath: nil, warning: nil }

  dir1, warn1 = helper.resolve_catalog_dirpath("Shoot_NoDotfile")
  raise "Expected #{cat1_base}, got #{dir1}" unless dir1 == cat1_base
  raise "Expected nil warning, got #{warn1.inspect}" unless warn1.nil?
  puts "1. Missing .gallery fallback passed."

  # 2. Comments-only / blank .gallery -> falls back cleanly with nil warning
  cat2_base = File.join(tmpdir, "Pictures", "Shoot_CommentsOnly", "darktable_exported")
  FileUtils.mkdir_p(cat2_base)
  File.write(File.join(cat2_base, Rails.configuration.photo_dotfile), "# comment line\n\n   # indented comment\n")

  res2 = helper.read_gallery_subpath(cat2_base)
  raise "Expected nil subpath for comments-only .gallery, got #{res2.inspect}" unless res2 == { subpath: nil, warning: nil }
  puts "2. Comments-only / blank .gallery fallback passed."

  # 3. Valid .gallery with comments + nested subpath ("2026/lrg")
  cat3_base = File.join(tmpdir, "Pictures", "Shoot_ValidSub", "darktable_exported")
  cat3_lrg  = File.join(cat3_base, "2026", "lrg")
  FileUtils.mkdir_p(cat3_lrg)
  File.write(File.join(cat3_base, Rails.configuration.photo_dotfile), "# Export target\n\n  2026/lrg  \n# trailing note\n")

  res3 = helper.read_gallery_subpath(cat3_base)
  raise "Expected subpath '2026/lrg', got #{res3.inspect}" unless res3 == { subpath: "2026/lrg", warning: nil }

  dir3, warn3 = helper.resolve_catalog_dirpath("Shoot_ValidSub")
  raise "Expected #{cat3_lrg}, got #{dir3}" unless dir3 == cat3_lrg
  raise "Expected nil warning, got #{warn3.inspect}" unless warn3.nil?
  raise "Expected file_to_path to match resolve_catalog_dirpath" unless helper.file_to_path("Shoot_ValidSub") == cat3_lrg
  puts "3. Valid .gallery nested subpath resolution passed."

  # 4. Guarded Constraint: Non-existent target directory in .gallery -> ignored with warning
  cat4_base = File.join(tmpdir, "Pictures", "Shoot_MissingTarget", "darktable_exported")
  FileUtils.mkdir_p(cat4_base)
  File.write(File.join(cat4_base, Rails.configuration.photo_dotfile), "nonexistent_dir\n")

  dir4, warn4 = helper.resolve_catalog_dirpath("Shoot_MissingTarget")
  raise "Expected fallback to #{cat4_base}, got #{dir4}" unless dir4 == cat4_base
  raise "Expected warning for missing target directory" unless warn4.to_s.include?("Ignored missing .gallery target")
  puts "4. Missing .gallery target fallback + warning passed."

  # 5. Guarded Constraint: Traversal attempt ("../escape") in .gallery -> ignored with warning
  cat5_base = File.join(tmpdir, "Pictures", "Shoot_Traversal", "darktable_exported")
  FileUtils.mkdir_p(cat5_base)
  File.write(File.join(cat5_base, Rails.configuration.photo_dotfile), "../escape\n")

  dir5, warn5 = helper.resolve_catalog_dirpath("Shoot_Traversal")
  raise "Expected fallback to #{cat5_base}, got #{dir5}" unless dir5 == cat5_base
  raise "Expected warning for traversal subpath" unless warn5.to_s.include?("Ignored invalid .gallery subpath")
  puts "5. Traversal attempt rejection + fallback warning passed."

ensure
  Rails.configuration.photo_path    = orig_photo_path
  Rails.configuration.photo_base    = orig_photo_base
  Rails.configuration.photo_source  = orig_photo_source
  Rails.configuration.photo_dotfile = orig_photo_dotfile
  FileUtils.rm_rf(tmpdir) if tmpdir && Dir.exist?(tmpdir)
end

puts "=== All CatalogHelper#read_gallery_subpath & resolve_catalog_dirpath Tests Passed ==="

# frozen_string_literal: true
# script/test_catalog_loadphotos_dotfile.rb
# Run via: bin/rails runner script/test_catalog_loadphotos_dotfile.rb [optional_path_to_sample.jpg]

require "tmpdir"
require "fileutils"
require "securerandom"

puts "=== Testing CatalogController#loadphotos with .gallery Dotfile Resolution ==="

helpers = Rails.application.routes.url_helpers
loadphotos_url = helpers.catalog_loadphotos_path

# Locate a real Darktable-exported JPEG (with EXIF CreateDate) to copy into temporary fixtures
sample_jpg = ARGV[0].presence || begin
  env = Gallery::Environ.instance
  Dir.glob(File.join(env.target_pictures_path, "**", env.photo_source, "**", "*.{jpg,JPG,jpeg,JPEG}")).first
end

raise "No sample JPEG found. Pass a path via: bin/rails runner script/test_catalog_loadphotos_dotfile.rb /path/to/photo.jpg" unless sample_jpg && File.file?(sample_jpg)
puts "Using sample JPEG fixture: #{sample_jpg}"

def assert_redirect_or_debug!(session, context_label)
  return if session.status == 302

  puts "  [FAIL DEBUG] #{context_label} HTTP status: #{session.status}"
  if (h1 = session.response.body.match(/<h1[^>]*>(.*?)<\/h1>/m))
    puts "  [FAIL DEBUG] Headline: #{h1[1].gsub(/<[^>]+>/, ' ').squeeze(' ').strip}"
  end
  if (msg = session.response.body.match(/<h2[^>]*>(.*?)<\/h2>/m))
    puts "  [FAIL DEBUG] Detail: #{msg[1].gsub(/<[^>]+>/, ' ').squeeze(' ').strip}"
  end
  raise "Expected 302 redirect during #{context_label}, got #{session.status}"
end

orig_forgery_setting = ActionController::Base.allow_forgery_protection
orig_photo_path      = Rails.configuration.photo_path
orig_photo_base      = Rails.configuration.photo_base
orig_photo_source    = Rails.configuration.photo_source
orig_photo_dotfile   = Rails.configuration.photo_dotfile

tmpdir = Dir.mktmpdir("gallery_loadphotos_dotfile_test_")
created_catalog_ids = []

ActionController::Base.allow_forgery_protection = false

begin
  Rails.configuration.photo_path    = tmpdir
  Rails.configuration.photo_base    = "Pictures"
  Rails.configuration.photo_source  = "darktable_exported"
  Rails.configuration.photo_dotfile = ".gallery"

  # ------------------------------------------------------------------
  # 1. Happy Path: .gallery points to "lrg" containing exported JPEGs
  # ------------------------------------------------------------------
  cat1_fname = "TestAlbum_Subdir_#{SecureRandom.hex(3)}"
  cat1_base  = File.join(tmpdir, "Pictures", cat1_fname, "darktable_exported")
  cat1_lrg   = File.join(cat1_base, "lrg")
  FileUtils.mkdir_p(cat1_lrg)
  File.write(File.join(cat1_base, ".gallery"), "# Use high-res exports\nlrg\n")
  FileUtils.cp(sample_jpg, File.join(cat1_lrg, "DSC_0101_lg.jpg"))
  FileUtils.cp(sample_jpg, File.join(cat1_lrg, "DSC_0102_lg.jpg"))

  session1 = ActionDispatch::Integration::Session.new(Rails.application)
  session1.host!("localhost")
  session1.post(loadphotos_url, params: { catalog: cat1_fname, name: "Subdir Album" })
  assert_redirect_or_debug!(session1, "Happy Path (.gallery -> lrg)")

  raise "Expected no flash alert on valid .gallery, got #{session1.flash[:alert].inspect}" if session1.flash[:alert].present?
  raise "Expected notice with 2 photos loaded, got #{session1.flash[:notice].inspect}" unless session1.flash[:notice].to_s.include?("2 photos loaded")

  cat1 = Catalog.find_by!(fname: cat1_fname)
  created_catalog_ids << cat1.id
  raise "Expected Catalog#fpath == #{cat1_lrg}, got #{cat1.fpath}" unless cat1.fpath == cat1_lrg
  raise "Expected 2 photos ingested, got #{cat1.photos.count}" unless cat1.photos.count == 2

  expected_fn = "#{cat1_fname}/darktable_exported/lrg/DSC_0101_lg.jpg"
  photo1 = cat1.photos.find_by!(photo_dsc: "DSC_0101")
  raise "Expected Photo#filename == #{expected_fn}, got #{photo1.filename}" unless photo1.filename == expected_fn
  puts "1. Happy path (.gallery -> lrg ingestion, Catalog#fpath, Photo#filename) passed."

  # ------------------------------------------------------------------
  # 2. Fallback Warning Path: Invalid/missing .gallery target, JPEGs in base folder
  # ------------------------------------------------------------------
  cat2_fname = "TestAlbum_Fallback_#{SecureRandom.hex(3)}"
  cat2_base  = File.join(tmpdir, "Pictures", cat2_fname, "darktable_exported")
  FileUtils.mkdir_p(cat2_base)
  File.write(File.join(cat2_base, ".gallery"), "nonexistent_subdir\n")
  FileUtils.cp(sample_jpg, File.join(cat2_base, "DSC_0201.jpg"))

  session2 = ActionDispatch::Integration::Session.new(Rails.application)
  session2.host!("localhost")
  session2.post(loadphotos_url, params: { catalog: cat2_fname })
  assert_redirect_or_debug!(session2, "Fallback Warning Path")

  raise "Expected warning in flash[:alert], got #{session2.flash[:alert].inspect}" unless session2.flash[:alert].to_s.include?("Ignored missing .gallery target")
  raise "Expected notice with 1 photo loaded, got #{session2.flash[:notice].inspect}" unless session2.flash[:notice].to_s.include?("1 photos loaded")

  cat2 = Catalog.find_by!(fname: cat2_fname)
  created_catalog_ids << cat2.id
  raise "Expected fallback Catalog#fpath == #{cat2_base}, got #{cat2.fpath}" unless cat2.fpath == cat2_base
  raise "Expected 1 photo ingested from base folder, got #{cat2.photos.count}" unless cat2.photos.count == 1
  puts "2. Fallback warning + base folder ingestion passed."

  # ------------------------------------------------------------------
  # 3. Guarded Constraint: Traversal in .gallery + empty base folder aborts cleanly
  # ------------------------------------------------------------------
  cat3_fname = "TestAlbum_EmptyAbort_#{SecureRandom.hex(3)}"
  cat3_base  = File.join(tmpdir, "Pictures", cat3_fname, "darktable_exported")
  FileUtils.mkdir_p(cat3_base)
  File.write(File.join(cat3_base, ".gallery"), "../outside\n")

  session3 = ActionDispatch::Integration::Session.new(Rails.application)
  session3.host!("localhost")
  session3.post(loadphotos_url, params: { catalog: cat3_fname })
  assert_redirect_or_debug!(session3, "Guarded Constraint (Empty Base Abort)")

  alert3 = session3.flash[:alert].to_s
  raise "Expected dotfile warning + ingestion abort in flash[:alert], got #{alert3.inspect}" unless alert3.include?("Ignored invalid .gallery subpath") && alert3.include?("Ingestion aborted")
  raise "Expected no Catalog record created on abort" if Catalog.exists?(fname: cat3_fname)
  puts "3. Traversal warning + empty base abort without residual Catalog passed."

ensure
  Catalog.where(id: created_catalog_ids).destroy_all if created_catalog_ids.any?
  Rails.configuration.photo_path    = orig_photo_path
  Rails.configuration.photo_base    = orig_photo_base
  Rails.configuration.photo_source  = orig_photo_source
  Rails.configuration.photo_dotfile = orig_photo_dotfile
  ActionController::Base.allow_forgery_protection = orig_forgery_setting
  FileUtils.rm_rf(tmpdir) if tmpdir && Dir.exist?(tmpdir)
end

puts "=== All CatalogController#loadphotos .gallery Dotfile Tests Passed ==="

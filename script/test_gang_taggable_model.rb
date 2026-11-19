# frozen_string_literal: true

# Usage: bin/rails runner script/test_gang_taggable_model.rb

puts "==> Starting validation for GangTaggable model concern..."

created = {
  categories:  [],
  tags:        [],
  catalogs:    [],
  photos:      [],
  portfolios:  [],
  exhibitions: []
}

begin
  token = Gallery::Environ.generate_token(8)

  cat = Category.create!(name: "TestCat_#{token}")
  created[:categories] << cat.id

  tag_a = Tag.create!(name: "TagA_#{token}", category: cat)
  tag_b = Tag.create!(name: "TagB_#{token}", category: cat)
  created[:tags].push(tag_a.id, tag_b.id)

  catalog = Catalog.create!(
    name:  "TestCatalog_#{token}",
    fname: "test_gang_#{token}",
    fpath: "/tmp/test_gang_#{token}"
  )
  created[:catalogs] << catalog.id

  photos = 3.times.map do |i|
    p = catalog.photos.create!(
      photo_dsc: "Gang Test Photo #{i + 1}",
      filename:  "test_gang_#{token}_#{i + 1}.jpg",
      photodate: Time.current,
      stars:     3
    )
    created[:photos] << p.id
    p
  end

  # Pre-tag photo[0] with tag_a to verify partial overlap (union OR, no duplicates)
  photos[0].tags << tag_a

  # 1. Catalog gang_assign_tag! (partial overlap -> 2 added, 1 skipped)
  res_cat = catalog.gang_assign_tag!(tag_a)
  raise "Catalog total_count mismatch"   unless res_cat.total_count == 3
  raise "Catalog added_count mismatch"   unless res_cat.added_count == 2
  raise "Catalog skipped_count mismatch" unless res_cat.skipped_count == 1
  raise "Catalog photos missing tag_a"   unless photos.all? { |p| p.reload.tag_ids.include?(tag_a.id) }
  raise "Duplicate join rows created"    unless photos[0].tags.where(id: tag_a.id).count == 1
  puts "  [PASS] Catalog#gang_assign_tag! performs idempotent union OR without duplicates."

  # 2. Re-running same tag yields 0 added, 3 skipped
  res_repeat = catalog.gang_assign_tag!(tag_a)
  raise "Repeat added_count should be 0"   unless res_repeat.added_count == 0
  raise "Repeat skipped_count should be 3" unless res_repeat.skipped_count == 3
  puts "  [PASS] Repeat assignment is a clean no-op (0 added, 3 skipped)."

  # 3. Portfolio gang_assign_tag! across subset of photos
  portfolio = Portfolio.create!(name: "port_gang_#{token}", title: "Portfolio Gang #{token}")
  created[:portfolios] << portfolio.id
  portfolio.portfolio_items.create!(photo: photos[0], position: 1)
  portfolio.portfolio_items.create!(photo: photos[1], position: 2)

  res_port = portfolio.gang_assign_tag!(tag_b)
  raise "Portfolio total_count mismatch" unless res_port.total_count == 2
  raise "Portfolio added_count mismatch" unless res_port.added_count == 2
  raise "Photo[0] missing tag_b"         unless photos[0].reload.tag_ids.include?(tag_b.id)
  raise "Photo[1] missing tag_b"         unless photos[1].reload.tag_ids.include?(tag_b.id)
  raise "Photo[2] wrongly tagged"        if photos[2].reload.tag_ids.include?(tag_b.id)
  puts "  [PASS] Portfolio#gang_assign_tag! tags only portfolio member items."

  # 4. Exhibition gang_assign_tag! with overlap
  exhibition = Exhibition.create!(title: "Exhibition Gang #{token}")
  created[:exhibitions] << exhibition.id
  exhibition.exhibition_items.create!(photo: photos[1], position: 1)
  exhibition.exhibition_items.create!(photo: photos[2], position: 2)

  res_exh = exhibition.gang_assign_tag!(tag_b)
  raise "Exhibition total_count mismatch"   unless res_exh.total_count == 2
  raise "Exhibition added_count mismatch"   unless res_exh.added_count == 1
  raise "Exhibition skipped_count mismatch" unless res_exh.skipped_count == 1
  raise "Photo[2] missing tag_b"            unless photos[2].reload.tag_ids.include?(tag_b.id)
  puts "  [PASS] Exhibition#gang_assign_tag! handles mixed tagged/untagged exhibition items."

  # 5. Guarded constraints: empty collection & invalid argument
  empty_exh = Exhibition.create!(title: "Empty Exhibition #{token}")
  created[:exhibitions] << empty_exh.id
  res_empty = empty_exh.gang_assign_tag!(tag_a)
  raise "Empty collection should return 0 total" unless res_empty.total_count == 0 && res_empty.added_count == 0

  raised_arg_err = false
  begin
    catalog.gang_assign_tag!(nil)
  rescue ArgumentError
    raised_arg_err = true
  end
  raise "Expected ArgumentError on nil tag" unless raised_arg_err
  puts "  [PASS] Empty collection and invalid argument guards verified."

  puts "==> All Phase 1 GangTaggable model checks passed successfully!"
ensure
  Exhibition.where(id: created[:exhibitions]).destroy_all
  Portfolio.where(id: created[:portfolios]).destroy_all
  Photo.where(id: created[:photos]).destroy_all
  Catalog.where(id: created[:catalogs]).destroy_all
  Tag.where(id: created[:tags]).destroy_all
  Category.where(id: created[:categories]).destroy_all
  puts "  [CLEANUP] Zero residual test records verified."
end

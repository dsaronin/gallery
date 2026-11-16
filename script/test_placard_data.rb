# frozen_string_literal: true

# script/test_placard_data.rb
# Run via: bin/rails runner script/test_placard_data.rb

require "securerandom"

puts "=== Testing Gallery::Environ::PlacardData API & Photo Baseline Integration ==="

PlacardData = Gallery::Environ::PlacardData

# 1. Verify field partitions are mutually exclusive and cover all 14 columns
overlap = PlacardData::ITEM_FIELDS & PlacardData::COLLECTION_FIELDS
raise "Expected ITEM_FIELDS and COLLECTION_FIELDS to be disjoint, got #{overlap}" unless overlap.empty?
raise "Expected 15 total fields, got #{PlacardData::ALL_FIELDS.size}" unless PlacardData::ALL_FIELDS.size == 15
puts "1. Disjoint ITEM_FIELDS (6) and COLLECTION_FIELDS (9) verified."

# 2. Verify Ruby class introspection across domain types
raise "Expected Photo => :item"          unless PlacardData.partition_for(Photo) == :item
raise "Expected PortfolioItem => :item"  unless PlacardData.partition_for(PortfolioItem) == :item
raise "Expected ExhibitionItem => :item" unless PlacardData.partition_for(ExhibitionItem) == :item
raise "Expected Portfolio => :collection"  unless PlacardData.partition_for(Portfolio) == :collection
raise "Expected Exhibition => :collection" unless PlacardData.partition_for(Exhibition) == :collection
raise "Expected Placard => :universal"   unless PlacardData.partition_for(Placard) == :universal
puts "2. Ruby metaprogramming class partition introspection verified."

# 3. Verify partition enforcement during merge
empty_pd = PlacardData.new
raise "Expected empty PlacardData active_partition to be :none" unless empty_pd.active_partition == :none

item_merged = empty_pd.merge(
  Photo,
  { title: "Test Title", artist_name: "Should Be Ignored By Item Partition" },
  status: :intrinsic
)
raise "Expected item_merged.item_partition? to be true" unless item_merged.item_partition?
raise "Expected item_merged.collection_partition? to be false" if item_merged.collection_partition?
raise "Expected title to be set" unless item_merged.title == "Test Title"
raise "Expected artist_name to be ignored on :item merge" unless item_merged.artist_name.nil?
puts "3. Partition enforcement and active_partition self-introspection verified."

# 4. Verify functional immutability, provenance transitions, and zero-value handling
col_merged = item_merged.merge(
  Portfolio,
  {
    title:       "Ignored Collection Title",
    artist_name: "David S. Anderson",
    medium:      "Archival Pigment Print",
    price:       0,
    cc_license:  0
  },
  status: :direct
)
raise "Expected original item_merged to remain unchanged" unless item_merged.artist_name.nil?
raise "Expected col_merged.collection_partition? to be true" unless col_merged.collection_partition?
raise "Expected title to remain 'Test Title'" unless col_merged.title == "Test Title"
raise "Expected title provenance to transition to :cascaded" unless col_merged.cascaded?(:title)
raise "Expected title origin source_class to remain 'Photo'" unless col_merged.provenance_for(:title)[:source_class] == "Photo"
raise "Expected artist_name to be :direct" unless col_merged.direct?(:artist_name)
raise "Expected price 0 to be preserved as present" unless col_merged.price == 0
raise "Expected cc_license 0 to resolve to :all_rights_reserved" unless col_merged.cc_license_key == :all_rights_reserved
puts "4. Functional immutability, provenance transitions (:intrinsic -> :cascaded), and numeric zero handling verified."

# 5. Verify live Photo#placard_data inside rollback transaction (zero residual data)
created_ids = { catalog_id: nil, photo_id: nil }

begin
  ActiveRecord::Base.transaction do
    rand_suffix = SecureRandom.hex(4)
    catalog = Catalog.create!(
      name:  "Test Catalog #{rand_suffix}",
      fname: "test_cat_#{rand_suffix}",
      fpath: "/tmp/test_cat_#{rand_suffix}"
    )
    created_ids[:catalog_id] = catalog.id

    photo = Photo.create!(
      catalog:   catalog,
      photo_dsc: "Morning Fog Over Oakland",
      filename:  "IMG_#{rand_suffix}.NEF",
      photodate: Time.zone.parse("2025-09-14 08:30:00"),
      latitude:  37.8044,
      longitude: -122.2712,
      notes:     "Shot from Grizzly Peak"
    )
    created_ids[:photo_id] = photo.id

    pd = photo.placard_data
    raise "Expected Photo#placard_data to return PlacardData" unless pd.is_a?(PlacardData)
    raise "Expected title 'Morning Fog Over Oakland', got '#{pd.title}'" unless pd.title == "Morning Fog Over Oakland"
    raise "Expected name alias to match title" unless pd.name == "Morning Fog Over Oakland"
    raise "Expected year '2025', got '#{pd.date_created_display}'" unless pd.date_created_display == "2025"
    raise "Expected coordinates '37.8044, -122.2712', got '#{pd.location_display}'" unless pd.location_display == "37.8044, -122.2712"
    raise "Expected curatorial_notes 'Shot from Grizzly Peak'" unless pd.curatorial_notes == "Shot from Grizzly Peak"
    raise "Expected intrinsic? to be true for :title" unless pd.intrinsic?(:title)

    # Verify chaining Photo -> Placard override
    override_placard = Placard.new(title: "Oakland Mist", medium: "Silver Gelatin")
    final_pd = override_placard.placard_data(pd)
    raise "Expected overridden title 'Oakland Mist'" unless final_pd.title == "Oakland Mist"
    raise "Expected :title to be :direct" unless final_pd.direct?(:title)
    raise "Expected :date_created_display to be :cascaded" unless final_pd.cascaded?(:date_created_display)
    raise "Expected universal Placard override to accept :medium" unless final_pd.medium == "Silver Gelatin"

    puts "5. Live Photo#placard_data and downstream Placard override verified."
    raise ActiveRecord::Rollback
  end
ensure
  Photo.where(id: created_ids[:photo_id]).delete_all if created_ids[:photo_id]
  Catalog.where(id: created_ids[:catalog_id]).delete_all if created_ids[:catalog_id]
end

raise "Residual Photo detected!" if created_ids[:photo_id] && Photo.exists?(created_ids[:photo_id])
raise "Residual Catalog detected!" if created_ids[:catalog_id] && Catalog.exists?(created_ids[:catalog_id])
puts "6. Zero residual test records verified."

puts "=== All Phase 1 PlacardData & Photo Baseline Tests Passed ==="

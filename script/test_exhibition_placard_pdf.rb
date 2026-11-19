# frozen_string_literal: true

# script/test_exhibition_placard_pdf.rb
# Run via: bin/rails runner script/test_exhibition_placard_pdf.rb

require "securerandom"

puts "=== Testing Exhibition Placard PDF Generation & Download Action ==="

helpers = Rails.application.routes.url_helpers

# 1. Verify member route helper
raise "Expected download_placards_exhibition_path(1) to be /exhibition/1/download_placards" unless helpers.download_placards_exhibition_path(1) == "/exhibition/1/download_placards"
puts "1. Exhibition download_placards route helper verified."

original_forgery_setting = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false

created_ids = {
  catalog_id: nil,
  photo_ids: [],
  exhibition_id: nil,
  exhibition_item_ids: [],
  placard_ids: []
}

begin
  ActiveRecord::Base.transaction do
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host!("localhost")
    rand_suffix = SecureRandom.hex(4)

    catalog = Catalog.create!(
      name:  "PDF Cat #{rand_suffix}",
      fname: "pdf_cat_#{rand_suffix}",
      fpath: "/tmp/pdf_cat_#{rand_suffix}"
    )
    created_ids[:catalog_id] = catalog.id

    master_placard = Placard.create!(
      artist_name:        "Kishindo",
      medium:             "Archival Pigment Print on Hahnemühle Rag",
      dimensions_display: "40 × 60 cm",
      price:              450
    )
    created_ids[:placard_ids] << master_placard.id

    exhibition = Exhibition.create!(
      title:   "PDF Test Exhibition #{rand_suffix}",
      placard: master_placard
    )
    created_ids[:exhibition_id] = exhibition.id

    # 2. Test empty exhibition PDF generation (0 items -> 1 valid PDF page)
    empty_pdf = ::Gallery::PlacardPdfGenerator.render(exhibition)
    raise "Expected valid PDF header on empty exhibition" unless empty_pdf.start_with?("%PDF-1.")
    puts "2. Empty exhibition graceful PDF fallback verified."

    # Create 5 items to verify 2x2 sheet ganging (4 on page 1, 1 on page 2 -> 2 pages)
    5.times do |idx|
      photo = Photo.create!(
        catalog:   catalog,
        photo_dsc: "Work Title #{idx + 1}",
        filename:  "PDF_#{rand_suffix}_#{idx + 1}.NEF",
        photodate: Time.zone.parse("2025-05-15 12:00:00")
      )
      created_ids[:photo_ids] << photo.id

      item_placard = Placard.create!(
        title:            "Curated Title #{idx + 1}",
        subtitle:         "Series Subtitle #{idx + 1}",
        curatorial_notes: "Curatorial note paragraph for print #{idx + 1}."
      )
      created_ids[:placard_ids] << item_placard.id

      item = ExhibitionItem.create!(
        exhibition: exhibition,
        photo:      photo,
        placard:    item_placard
      )
      created_ids[:exhibition_item_ids] << item.id
    end

    # 3. Verify 5 items produce a 2-page PDF (2x2 ganging on US Letter)
    ganged_pdf = ::Gallery::PlacardPdfGenerator.render(exhibition)
    raise "Expected valid PDF header on ganged sheet" unless ganged_pdf.start_with?("%PDF-1.")
    page_count = ganged_pdf.scan(/\/Type\s*\/Page\b/).size
    raise "Expected 2 PDF pages for 5 items (2x2 ganging), got #{page_count}" unless page_count == 2
    puts "3. 2x2 sheet ganging pagination (5 items -> 2 pages) verified."

    # 4. Verify group mode and paper size variants (:a5, :a7)
    group_a5_pdf = ::Gallery::PlacardPdfGenerator.render(exhibition, paper_size: :a5, mode: :group)
    raise "Expected valid PDF header for :a5 / :group" unless group_a5_pdf.start_with?("%PDF-1.")
    a5_pages = group_a5_pdf.scan(/\/Type\s*\/Page\b/).size
    raise "Expected 3 PDF pages for 5 items on :a5 (1x2 ganging), got #{a5_pages}" unless a5_pages == 3

    a7_pdf = ::Gallery::PlacardPdfGenerator.render(exhibition, paper_size: :a7)
    a7_pages = a7_pdf.scan(/\/Type\s*\/Page\b/).size
    raise "Expected 1 PDF page for 5 items on :a7 (2x4 ganging), got #{a7_pages}" unless a7_pages == 1
    puts "4. Variant paper sizes (:a5 -> 3 pages, :a7 -> 1 page) and :group mode verified."

    # 5. Test GET /exhibition/:id/download_placards HTTP response
    session.get(helpers.download_placards_exhibition_path(exhibition))
    raise "Expected 200 OK on GET download_placards, got #{session.status}" unless session.status == 200
    raise "Expected application/pdf Content-Type, got #{session.response.content_type}" unless session.response.content_type.include?("application/pdf")
    raise "Expected inline Content-Disposition, got #{session.response.headers['Content-Disposition']}" unless session.response.headers["Content-Disposition"].to_s.include?("inline")
    raise "Expected parameterized filename in Content-Disposition" unless session.response.headers["Content-Disposition"].to_s.include?("#{exhibition.title.parameterize}-placards.pdf")
    raise "Expected binary PDF body" unless session.response.body.b.start_with?("%PDF-1.".b)
    puts "5. GET /exhibition/:id/download_placards HTTP response, headers, and PDF body verified."

    # 6. Test Exhibition#show renders the 'placards (pdf)' link when items exist
    session.get(helpers.exhibition_path(exhibition))
    raise "Expected 200 OK on GET /exhibition/:id, got #{session.status}" unless session.status == 200
    raise "Expected Exhibition#show to render download link" unless session.response.body.include?(helpers.download_placards_exhibition_path(exhibition))
    puts "6. Exhibition#show PDF download link rendering verified."

    # 7. Test missing Exhibition guard
    session.get(helpers.download_placards_exhibition_path(999_999_999))
    raise "Expected 302 redirect on missing Exhibition, got #{session.status}" unless session.status == 302
    raise "Expected alert flash on missing Exhibition" if session.flash[:alert].blank?
    puts "7. Missing Exhibition guard verified."

    raise ActiveRecord::Rollback
  end
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
  ExhibitionItem.where(id: created_ids[:exhibition_item_ids]).delete_all if created_ids[:exhibition_item_ids].any?
  Exhibition.where(id: created_ids[:exhibition_id]).delete_all if created_ids[:exhibition_id]
  Photo.where(id: created_ids[:photo_ids]).delete_all if created_ids[:photo_ids].any?
  Catalog.where(id: created_ids[:catalog_id]).delete_all if created_ids[:catalog_id]
  Placard.where(id: created_ids[:placard_ids]).delete_all if created_ids[:placard_ids].any?
end

raise "Residual Placards detected!" if created_ids[:placard_ids].any? && Placard.where(id: created_ids[:placard_ids]).exists?
raise "Residual Exhibition detected!" if created_ids[:exhibition_id] && Exhibition.exists?(created_ids[:exhibition_id])
raise "Residual Photos detected!" if created_ids[:photo_ids].any? && Photo.where(id: created_ids[:photo_ids]).exists?
raise "Residual Catalog detected!" if created_ids[:catalog_id] && Catalog.exists?(created_ids[:catalog_id])
puts "8. Zero residual test records verified."

puts "=== All Exhibition Placard PDF Tests Passed ==="

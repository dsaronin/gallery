# script/test_exhibition_views.rb
# Run via: bin/rails runner script/test_exhibition_views.rb

require "securerandom"

puts "=== Testing Exhibition Views & Curation Flow ==="

helpers = Rails.application.routes.url_helpers
original_forgery_setting = ActionController::Base.allow_forgery_protection
ActionController::Base.allow_forgery_protection = false

begin
  ActiveRecord::Base.transaction do
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host!("localhost")
    rand_suffix = SecureRandom.hex(4)

    # 1. GET /exhibition (index)
    session.get(helpers.exhibition_index_path, headers: { "Accept" => "text/html" })
    raise "Expected 200 OK on GET /exhibition, got #{session.status}" unless session.status == 200
    puts "1. GET /exhibition (index) rendered (HTTP 200)."

    # 2. GET /exhibition/new
    session.get(helpers.new_exhibition_path, headers: { "Accept" => "text/html" })
    raise "Expected 200 OK on GET /exhibition/new, got #{session.status}" unless session.status == 200
    raise "Expected form input for exhibition[title]" unless session.response.body.include?("exhibition[title]")
    raise "Expected Option A new form to omit exhibition[status]" if session.response.body.include?("exhibition[status]")
    puts "2. GET /exhibition/new rendered with Option A fields (HTTP 200)."

    # 3. Create exhibition and test GET /exhibition/:id (empty show)
    catalog = Catalog.create!(name: "View Cat #{rand_suffix}", fname: "view_cat_#{rand_suffix}", fpath: "/tmp/view_test")
    photo = catalog.photos.create!(
      photo_dsc: "View Test Shot #{rand_suffix}",
      filename: "view_#{rand_suffix}.jpg",
      photodate: Time.current,
      stars: 5
    )

    exhibition = Exhibition.create!(
      title: "View Test Exhibition #{rand_suffix}",
      sales_policy: :direct_inquiry,
      budget: 2000
    )

    session.get(helpers.exhibition_path(exhibition), headers: { "Accept" => "text/html" })
    raise "Expected 200 OK on GET /exhibition/:id (empty), got #{session.status}" unless session.status == 200
    raise "Expected empty state message on show view" unless session.response.body.include?("does not contain any curated photos yet")
    puts "3. GET /exhibition/:id (empty state) rendered (HTTP 200)."

    # 4. GET /exhibition/:id/edit
    session.get(helpers.edit_exhibition_path(exhibition), headers: { "Accept" => "text/html" })
    raise "Expected 200 OK on GET /exhibition/:id/edit, got #{session.status}" unless session.status == 200
    raise "Expected Option A edit form to include exhibition[status]" unless session.response.body.include?("exhibition[status]")
    puts "4. GET /exhibition/:id/edit rendered with full fields (HTTP 200)."

    # 5. Curation preview + commit -> populated GET /exhibition/:id
    session.post(helpers.preview_exhibition_curation_path(exhibition), params: {
      curation_criteria: {
        sources: { catalog_ids: [catalog.id] },
        min_stars: 5
      }
    })
    raise "Expected 200 OK on curation preview, got #{session.status}" unless session.status == 200

    session.post(helpers.commit_exhibition_curation_path(exhibition))
    raise "Expected 302 redirect on curation commit, got #{session.status}" unless session.status == 302
    raise "Expected redirect to exhibition show path" unless session.response.location.end_with?(helpers.exhibition_path(exhibition))

    session.get(helpers.exhibition_path(exhibition), headers: { "Accept" => "text/html" })
    raise "Expected 200 OK on populated GET /exhibition/:id, got #{session.status}" unless session.status == 200
    raise "Expected curated photo description '#{photo.photo_dsc}' in show view" unless session.response.body.include?(photo.photo_dsc)
    puts "5. Curation commit and populated GET /exhibition/:id rendered (HTTP 200)."

    # 6. Dashboard renders with active current_exhibition
    session.get(helpers.dashboard_path, headers: { "Accept" => "text/html" })
    raise "Expected 200 OK on GET /dashboard, got #{session.status}" unless session.status == 200
    raise "Expected dashboard to link to current exhibition" unless session.response.body.include?(helpers.exhibition_path(exhibition))
    puts "6. GET /dashboard rendered with wired Exhibition links (HTTP 200)."

    raise ActiveRecord::Rollback
  end
ensure
  ActionController::Base.allow_forgery_protection = original_forgery_setting
end

puts "=== All Exhibition View & Curation Integration Tests Passed ==="

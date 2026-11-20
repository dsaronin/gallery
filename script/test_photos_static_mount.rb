# script/test_photos_static_mount.rb
# Run via: bin/rails runner script/test_photos_static_mount.rb

require "erb"

puts "=== Testing /photos Rack::Files Mount (No Symlink) ==="

# 1. Confirm legacy initializer and public/photos symlink are absent
initializer_path = Rails.root.join("config/initializers/photos_symlink.rb")
symlink_path     = Rails.root.join("public/photos")

raise "Legacy initializer still exists: #{initializer_path}" if initializer_path.exist?
raise "Legacy public/photos still exists: #{symlink_path}" if symlink_path.exist? || symlink_path.symlink?
puts "1. Legacy initializer and public/photos symlink confirmed absent."

# 2. Locate an existing photo file under target_pictures_path
pictures_root = Gallery::Environ.instance.target_pictures_path
raise "Pictures directory not mounted/accessible: #{pictures_root}" unless File.directory?(pictures_root)

sample_photo = Photo.find do |p|
  next if p.filename.blank?
  File.file?(File.join(pictures_root, p.filename))
end

raise "No accessible Photo file found under #{pictures_root} to test HTTP delivery" unless sample_photo
encoded_subpath = sample_photo.filename.split("/").map { |seg| ERB::Util.url_encode(seg) }.join("/")
relative_url    = "/photos/#{encoded_subpath}"

session = ActionDispatch::Integration::Session.new(Rails.application)
session.host!("localhost")

# 3. Happy path: GET /photos/<photo.filename> returns 200 and image content
session.get(relative_url)
raise "Expected 200 for #{relative_url}, got #{session.status}" unless session.status == 200
content_type = session.response.content_type.to_s
raise "Expected image/* content-type, got #{content_type.inspect}" unless content_type.start_with?("image/")
raise "Expected non-empty image body" unless session.response.body.bytesize > 0
puts "2. Happy path GET #{relative_url} passed (200, #{content_type}, #{session.response.body.bytesize} bytes)."

# 4. Guarded constraint: missing file returns 404
session.get("/photos/__nonexistent_gallery_probe__.jpg")
raise "Expected 404 for missing file, got #{session.status}" unless session.status == 404
puts "3. Missing file returned 404."

# 5. Guarded constraint: path traversal attempt is rejected
session.get("/photos/../../../../etc/passwd")
raise "Expected 400 or 404 for traversal attempt, got #{session.status}" unless [400, 404].include?(session.status)
puts "4. Path traversal attempt rejected (#{session.status})."

puts "=== All /photos Mount Tests Passed ==="

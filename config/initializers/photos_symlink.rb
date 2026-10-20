# config/initializers/photos_symlink.rb
# to properly resolve paths to the actual photos within a Rails system
# we'll need to make sure a symlink to the photos disk/directory exists or
# needs to be created. This will make sure this is machine independent

Rails.application.config.after_initialize do
  target_dir = File.join(Rails.configuration.photo_path, Rails.configuration.photo_base)
  link_path  = Rails.root.join("public", "photos")

  if File.directory?(target_dir)
    # Check if link exists or is a broken symlink
    if link_path.symlink?
      current_target = link_path.readlink.to_s
      unless current_target == target_dir
        link_path.unlink
        File.symlink(target_dir, link_path)
        Rails.logger.info("[Gallery] Updated symlink public/photos -> #{target_dir}")
      end
    elsif !link_path.exist?
      File.symlink(target_dir, link_path)
      Rails.logger.info("[Gallery] Created symlink public/photos -> #{target_dir}")
    end
  else
    Rails.logger.warn("[Gallery] Photo target directory not found: #{target_dir}")
  end
end

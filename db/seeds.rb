require "yaml"

puts "== Seeding Database =="

# 1. Categories
categories_file = Rails.root.join("db", "seeds", "categories.yml")
if File.exist?(categories_file)
  categories = YAML.safe_load_file(categories_file) || []
  puts "Loading Categories from #{categories_file.basename}..."

  categories.each do |entry|
    category = Category.find_or_initialize_by(name: entry["name"])
    if category.new_record?
      category.save!
      puts "  [CREATE] Category: #{category.name}"
    else
      puts "  [EXISTS] Category: #{category.name}"
    end
  end
end

# 2. Tags
tags_file = Rails.root.join("db", "seeds", "tags.yml")
if File.exist?(tags_file)
  tags = YAML.safe_load_file(tags_file) || []
  puts "Loading Tags from #{tags_file.basename}..."

  tags.each do |entry|
    category = Category.find_by(name: entry["category"])
    unless category
      puts "  [WARN] Category '#{entry['category']}' not found for tag '#{entry['name']}'. Skipping."
      next
    end

    tag = Tag.find_or_initialize_by(name: entry["name"], category: category)
    tag.theme = entry.fetch("theme", false)

    if tag.new_record?
      tag.save!
      puts "  [CREATE] Tag: #{tag.name} (Category: #{category.name}, Theme: #{tag.theme})"
    else
      tag.save! if tag.changed?
      puts "  [EXISTS] Tag: #{tag.name} (Category: #{category.name})"
    end
  end
end

# 3. Talents
talents_file = Rails.root.join("db", "seeds", "talents.yml")
if File.exist?(talents_file)
  talents = YAML.safe_load_file(talents_file) || []
  puts "Loading Talents from #{talents_file.basename}..."

  talents.each do |entry|
    talent = Talent.find_or_initialize_by(talent_code: entry["talent_code"])
    talent.talent_name    = entry["talent_name"]
    talent.first_name     = entry["first_name"]
    talent.last_name      = entry["last_name"]
    talent.talent_dob     = entry["talent_dob"]
    talent.talent_address = entry["talent_address"]
    talent.talent_email   = entry["talent_email"]
    talent.talent_phone   = entry["talent_phone"]
    talent.talent_release = entry["talent_release"]

    if talent.new_record?
      talent.save!
      puts "  [CREATE] Talent: #{talent.talent_name} (#{talent.talent_code})"
    else
      talent.save! if talent.changed?
      puts "  [EXISTS] Talent: #{talent.talent_name} (#{talent.talent_code})"
    end
  end
end

puts "== Seeding Complete =="


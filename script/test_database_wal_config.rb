# script/test_database_wal_config.rb
# Run via: bin/rails runner script/test_database_wal_config.rb

require "erb"
require "yaml"
require "tempfile"

puts "=== Testing Database Path Config & SQLite WAL Mode ==="

# 1. Verify config/database.yml is not ignored by Git
ignored = system("git check-ignore -q config/database.yml")
raise "config/database.yml is still ignored by Git!" if ignored
puts "1. config/database.yml confirmed tracked (not gitignored)."

# 2. Verify DATABASE_PATH interpolation in config/database.yml
raw_yaml = File.read(Rails.root.join("config/database.yml"))

orig_db_path = ENV["DATABASE_PATH"]
begin
  ENV.delete("DATABASE_PATH")
  default_cfg = YAML.safe_load(ERB.new(raw_yaml).result, aliases: true)
  raise "Expected default production db to be db/production.sqlite3, got #{default_cfg.dig("production", "database").inspect}" unless default_cfg.dig("production", "database") == "db/production.sqlite3"

  ENV["DATABASE_PATH"] = "/home/gallery/data/production.sqlite3"
  custom_cfg = YAML.safe_load(ERB.new(raw_yaml).result, aliases: true)
  raise "Expected custom production db path, got #{custom_cfg.dig("production", "database").inspect}" unless custom_cfg.dig("production", "database") == "/home/gallery/data/production.sqlite3"
  puts "2. DATABASE_PATH interpolation in config/database.yml passed."
ensure
  orig_db_path ? ENV["DATABASE_PATH"] = orig_db_path : ENV.delete("DATABASE_PATH")
end

# 3. Verify active SQLite connection has WAL mode and NORMAL sync enabled
journal_mode = ActiveRecord::Base.connection.select_value("PRAGMA journal_mode;").to_s.downcase
sync_mode    = ActiveRecord::Base.connection.select_value("PRAGMA synchronous;").to_i

raise "Expected journal_mode 'wal', got #{journal_mode.inspect}" unless journal_mode == "wal"
raise "Expected synchronous mode 1 (NORMAL), got #{sync_mode.inspect}" unless sync_mode == 1
puts "3. Active SQLite connection PRAGMAs verified (journal_mode=#{journal_mode}, synchronous=#{sync_mode})."

puts "=== All Database & WAL Tests Passed ==="

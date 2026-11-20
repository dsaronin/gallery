# frozen_string_literal: true

# Enable SQLite Write-Ahead Logging (WAL) and NORMAL synchronization
# for improved read/write concurrency and safe online backups.
ActiveSupport.on_load(:active_record) do
  if ActiveRecord::Base.connection_db_config.adapter == "sqlite3"
    conn = ActiveRecord::Base.connection
    conn.execute("PRAGMA journal_mode = WAL;")
    conn.execute("PRAGMA synchronous = NORMAL;")
  end
end

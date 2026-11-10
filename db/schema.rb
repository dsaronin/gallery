# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_11_04_185836) do
  create_table "catalogs", force: :cascade do |t|
    t.string "name"
    t.string "fname"
    t.string "fpath"
    t.integer "talent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fname"], name: "index_catalogs_on_fname", unique: true
    t.index ["talent_id"], name: "index_catalogs_on_talent_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "exhibition_items", force: :cascade do |t|
    t.integer "position", null: false
    t.integer "likes_count", default: 0, null: false
    t.integer "placard_id"
    t.integer "exhibition_id", null: false
    t.integer "photo_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exhibition_id", "photo_id"], name: "index_exhibition_items_on_exhibition_id_and_photo_id", unique: true
    t.index ["exhibition_id", "position"], name: "index_exhibition_items_on_exhibition_id_and_position", unique: true
    t.index ["exhibition_id"], name: "index_exhibition_items_on_exhibition_id"
    t.index ["photo_id"], name: "index_exhibition_items_on_photo_id"
    t.index ["placard_id"], name: "index_exhibition_items_on_placard_id"
  end

  create_table "exhibitions", force: :cascade do |t|
    t.string "title", null: false
    t.integer "status", default: 0, null: false
    t.integer "sales_policy", default: 0, null: false
    t.integer "budget"
    t.integer "total_expenses"
    t.date "approved_by_artist_at"
    t.date "approved_by_venue_at"
    t.bigint "showing_id"
    t.integer "portfolio_id"
    t.integer "venue_id"
    t.integer "placard_id"
    t.integer "talent_id"
    t.text "curation_criteria"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["placard_id"], name: "index_exhibitions_on_placard_id"
    t.index ["portfolio_id"], name: "index_exhibitions_on_portfolio_id"
    t.index ["showing_id"], name: "index_exhibitions_on_showing_id"
    t.index ["talent_id"], name: "index_exhibitions_on_talent_id"
    t.index ["venue_id"], name: "index_exhibitions_on_venue_id"
  end

  create_table "photos", force: :cascade do |t|
    t.string "photo_dsc"
    t.string "filename"
    t.integer "stars", default: 0, null: false
    t.datetime "photodate"
    t.integer "width"
    t.integer "height"
    t.float "latitude"
    t.float "longitude"
    t.string "notes"
    t.integer "catalog_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["catalog_id"], name: "index_photos_on_catalog_id"
  end

  create_table "photos_tags", id: false, force: :cascade do |t|
    t.integer "photo_id", null: false
    t.integer "tag_id", null: false
    t.index ["photo_id", "tag_id"], name: "index_photos_tags_on_photo_id_and_tag_id", unique: true
    t.index ["tag_id", "photo_id"], name: "index_photos_tags_on_tag_id_and_photo_id"
  end

  create_table "placards", force: :cascade do |t|
    t.string "title"
    t.string "subtitle"
    t.text "curatorial_notes"
    t.string "artist_name"
    t.string "date_created_display"
    t.string "location_display"
    t.string "medium"
    t.string "dimensions_display"
    t.string "edition_info"
    t.integer "price"
    t.string "sales_notes"
    t.integer "cc_license", default: 0, null: false
    t.integer "copyright_year"
    t.string "copyright_holder"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "portfolio_items", force: :cascade do |t|
    t.integer "position", null: false
    t.integer "likes_count", default: 0, null: false
    t.integer "placard_id"
    t.integer "portfolio_id", null: false
    t.integer "photo_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["photo_id"], name: "index_portfolio_items_on_photo_id"
    t.index ["placard_id"], name: "index_portfolio_items_on_placard_id"
    t.index ["portfolio_id", "photo_id"], name: "index_portfolio_items_on_portfolio_id_and_photo_id", unique: true
    t.index ["portfolio_id", "position"], name: "index_portfolio_items_on_portfolio_id_and_position", unique: true
    t.index ["portfolio_id"], name: "index_portfolio_items_on_portfolio_id"
  end

  create_table "portfolios", force: :cascade do |t|
    t.string "name", null: false
    t.string "title", null: false
    t.integer "status", default: 0, null: false
    t.integer "likes_count", default: 0, null: false
    t.integer "placard_id"
    t.string "share_token"
    t.text "curation_criteria"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_portfolios_on_name", unique: true
    t.index ["placard_id"], name: "index_portfolios_on_placard_id"
    t.index ["share_token"], name: "index_portfolios_on_share_token", unique: true
  end

  create_table "showings", force: :cascade do |t|
    t.string "title"
    t.integer "status", default: 0, null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "prep_days", default: 1, null: false
    t.integer "teardown_days", default: 1, null: false
    t.integer "rental_cost"
    t.datetime "reception_date"
    t.integer "visitation_count", default: 0, null: false
    t.text "notes"
    t.integer "exhibition_id", null: false
    t.integer "venue_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exhibition_id"], name: "index_showings_on_exhibition_id"
    t.index ["venue_id"], name: "index_showings_on_venue_id"
  end

  create_table "tags", force: :cascade do |t|
    t.integer "category_id", null: false
    t.string "name", null: false
    t.boolean "theme", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "name"], name: "index_tags_on_category_id_and_name", unique: true
    t.index ["category_id"], name: "index_tags_on_category_id"
    t.index ["theme"], name: "index_tags_on_theme"
  end

  create_table "talent", force: :cascade do |t|
    t.string "talent_code"
    t.string "talent_name"
    t.string "last_name"
    t.string "first_name"
    t.date "talent_dob"
    t.string "talent_address"
    t.string "talent_email"
    t.string "talent_phone"
    t.date "talent_release"
    t.integer "cover_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cover_id"], name: "index_talent_on_cover_id"
    t.index ["talent_code"], name: "index_talent_on_talent_code", unique: true
  end

  create_table "venues", force: :cascade do |t|
    t.string "name", null: false
    t.integer "venue_type", default: 0, null: false
    t.string "space_name"
    t.integer "wall_linear_meters"
    t.integer "rate_per_day"
    t.string "address"
    t.string "contact_name"
    t.string "contact_position"
    t.string "contact_email"
    t.string "contact_phone"
    t.string "website_url"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "catalogs", "talent"
  add_foreign_key "exhibition_items", "exhibitions"
  add_foreign_key "exhibition_items", "photos"
  add_foreign_key "exhibition_items", "placards"
  add_foreign_key "exhibitions", "placards"
  add_foreign_key "exhibitions", "portfolios"
  add_foreign_key "exhibitions", "showings"
  add_foreign_key "exhibitions", "talent"
  add_foreign_key "exhibitions", "venues"
  add_foreign_key "photos", "catalogs"
  add_foreign_key "portfolio_items", "photos"
  add_foreign_key "portfolio_items", "placards"
  add_foreign_key "portfolio_items", "portfolios"
  add_foreign_key "portfolios", "placards"
  add_foreign_key "showings", "exhibitions"
  add_foreign_key "showings", "venues"
  add_foreign_key "tags", "categories"
  add_foreign_key "talent", "photos", column: "cover_id"
end

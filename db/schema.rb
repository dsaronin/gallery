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

ActiveRecord::Schema[7.0].define(version: 2023_11_25_213606) do
  create_table "folders", force: :cascade do |t|
    t.string "fname"
    t.string "fpath"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fname"], name: "index_folders_on_fname", unique: true
  end

  create_table "photos", force: :cascade do |t|
    t.string "photo_dsc"
    t.string "filename"
    t.integer "rating"
    t.datetime "photodate"
    t.integer "width"
    t.integer "height"
    t.float "latitude"
    t.float "longitude"
    t.string "notes"
    t.integer "folder_id", null: false
    t.integer "talent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["folder_id"], name: "index_photos_on_folder_id"
    t.index ["talent_id"], name: "index_photos_on_talent_id"
  end

  create_table "photos_portfolio_items", id: false, force: :cascade do |t|
    t.integer "photo_id", null: false
    t.integer "portfolio_item_id", null: false
  end

  create_table "portfolio_items", force: :cascade do |t|
    t.string "comment"
    t.integer "position"
    t.integer "portfolio_id", null: false
    t.integer "photo_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["photo_id"], name: "index_portfolio_items_on_photo_id"
    t.index ["portfolio_id"], name: "index_portfolio_items_on_portfolio_id"
  end

  create_table "portfolios", force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_portfolios_on_name", unique: true
  end

  create_table "talent", force: :cascade do |t|
    t.string "talent_code"
    t.string "talent_nbr"
    t.string "talent_name"
    t.string "first_name"
    t.string "last_name"
    t.date "talent_dob"
    t.date "talent_release"
    t.integer "cover_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cover_id"], name: "index_talent_on_cover_id"
    t.index ["talent_code"], name: "index_talent_on_talent_code", unique: true
  end

  add_foreign_key "photos", "folders"
  add_foreign_key "photos", "talent"
  add_foreign_key "portfolio_items", "photos"
  add_foreign_key "portfolio_items", "portfolios"
  add_foreign_key "talent", "covers"
end

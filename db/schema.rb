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

ActiveRecord::Schema[7.0].define(version: 2023_09_16_021431) do
  create_table "folders", force: :cascade do |t|
    t.string "name"
    t.string "path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_folders_on_name", unique: true
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
    t.integer "portfolio_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["folder_id"], name: "index_photos_on_folder_id"
    t.index ["portfolio_id"], name: "index_photos_on_portfolio_id"
    t.index ["talent_id"], name: "index_photos_on_talent_id"
  end

  create_table "portfolios", force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_portfolios_on_name", unique: true
  end

  create_table "talents", force: :cascade do |t|
    t.string "model_code"
    t.string "model_name"
    t.string "first_name"
    t.string "last_name"
    t.string "gender"
    t.integer "shoot_age"
    t.date "model_release"
    t.string "model_nbr"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["model_code"], name: "index_talents_on_model_code", unique: true
  end

  add_foreign_key "photos", "folders"
  add_foreign_key "photos", "portfolios"
  add_foreign_key "photos", "talents"
end

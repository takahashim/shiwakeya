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

ActiveRecord::Schema[8.0].define(version: 2025_08_09_122824) do
  create_table "service_sheets", force: :cascade do |t|
    t.integer "service_spreadsheet_id", null: false
    t.string "sheet_name"
    t.string "purpose"
    t.datetime "last_synced_at"
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_spreadsheet_id"], name: "index_service_sheets_on_service_spreadsheet_id"
  end

  create_table "service_spreadsheets", force: :cascade do |t|
    t.string "name", null: false
    t.string "spreadsheet_id", null: false
    t.text "description"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spreadsheet_id"], name: "index_service_spreadsheets_on_spreadsheet_id", unique: true
  end

  create_table "user_spreadsheet_permissions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "service_spreadsheet_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_spreadsheet_id"], name: "index_user_spreadsheet_permissions_on_service_spreadsheet_id"
    t.index ["user_id", "service_spreadsheet_id"], name: "index_user_spreadsheet_permissions_unique", unique: true
    t.index ["user_id"], name: "index_user_spreadsheet_permissions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "service_sheets", "service_spreadsheets"
  add_foreign_key "user_spreadsheet_permissions", "service_spreadsheets"
  add_foreign_key "user_spreadsheet_permissions", "users"
end

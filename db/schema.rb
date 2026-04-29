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

ActiveRecord::Schema[8.1].define(version: 2026_04_29_115122) do
  create_table "checks", force: :cascade do |t|
    t.datetime "checked_at", null: false
    t.datetime "created_at", null: false
    t.string "error_message"
    t.integer "keyword_id", null: false
    t.integer "position"
    t.string "serpapi_search_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["keyword_id", "checked_at"], name: "index_checks_on_keyword_id_and_checked_at"
    t.index ["keyword_id"], name: "index_checks_on_keyword_id"
  end

  create_table "keywords", force: :cascade do |t|
    t.string "check_frequency", default: "daily", null: false
    t.datetime "created_at", null: false
    t.datetime "last_checked_at"
    t.string "location", default: "us", null: false
    t.string "query", null: false
    t.integer "site_id", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "query"], name: "index_keywords_on_site_id_and_query", unique: true
    t.index ["site_id"], name: "index_keywords_on_site_id"
  end

  create_table "sites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "domain", null: false
    t.string "name", null: false
    t.boolean "tracking_enabled", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_sites_on_domain", unique: true
  end

  create_table "tenants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "serpapi_key", default: "", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "checks", "keywords", on_delete: :cascade
  add_foreign_key "keywords", "sites", on_delete: :cascade
end

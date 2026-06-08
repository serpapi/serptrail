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

ActiveRecord::Schema[8.1].define(version: 2026_06_08_073333) do
  create_table "checks", force: :cascade do |t|
    t.integer "ai_overview_citation_position"
    t.boolean "ai_overview_cited"
    t.boolean "ai_overview_present"
    t.datetime "checked_at", null: false
    t.datetime "created_at", null: false
    t.string "error_message"
    t.integer "keyword_id", null: false
    t.integer "keyword_target_id"
    t.string "location", null: false
    t.integer "position"
    t.string "query", null: false
    t.integer "search_run_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["keyword_id", "checked_at"], name: "index_checks_on_keyword_id_and_checked_at"
    t.index ["keyword_id"], name: "index_checks_on_keyword_id"
    t.index ["keyword_target_id", "search_run_id"], name: "index_checks_on_keyword_target_id_and_search_run_id", unique: true
    t.index ["keyword_target_id"], name: "index_checks_on_keyword_target_id"
    t.index ["search_run_id"], name: "index_checks_on_search_run_id"
  end

  create_table "keyword_targets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "keyword_id", null: false
    t.integer "site_id", null: false
    t.boolean "tracking_enabled", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["keyword_id", "site_id"], name: "index_keyword_targets_on_keyword_id_and_site_id", unique: true
    t.index ["keyword_id"], name: "index_keyword_targets_on_keyword_id"
    t.index ["site_id"], name: "index_keyword_targets_on_site_id"
  end

  create_table "keywords", force: :cascade do |t|
    t.string "check_frequency", default: "daily", null: false
    t.datetime "created_at", null: false
    t.datetime "last_checked_at"
    t.json "locations"
    t.string "query", null: false
    t.integer "site_id"
    t.datetime "updated_at", null: false
    t.index ["site_id", "query"], name: "index_keywords_on_site_id_and_query", unique: true
    t.index ["site_id"], name: "index_keywords_on_site_id"
  end

  create_table "search_runs", force: :cascade do |t|
    t.datetime "checked_at", null: false
    t.datetime "created_at", null: false
    t.string "error_message"
    t.integer "keyword_id", null: false
    t.string "location", null: false
    t.string "query", null: false
    t.text "raw_response"
    t.json "search_params"
    t.string "serpapi_search_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["keyword_id", "location", "checked_at"], name: "index_search_runs_on_keyword_id_and_location_and_checked_at"
    t.index ["keyword_id"], name: "index_search_runs_on_keyword_id"
    t.index ["query", "location", "checked_at"], name: "index_search_runs_on_query_and_location_and_checked_at"
  end

  create_table "sites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "domain", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_sites_on_domain", unique: true
  end

  create_table "tenants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "serpapi_key", default: "", null: false
    t.datetime "updated_at", null: false
  end

  create_table "view_series", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "keyword_id", null: false
    t.integer "keyword_target_id"
    t.string "location", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "view_id", null: false
    t.index ["keyword_id"], name: "index_view_series_on_keyword_id"
    t.index ["keyword_target_id"], name: "index_view_series_on_keyword_target_id"
    t.index ["view_id"], name: "index_view_series_on_view_id"
  end

  create_table "views", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "checks", "keyword_targets"
  add_foreign_key "checks", "keywords", on_delete: :cascade
  add_foreign_key "checks", "search_runs"
  add_foreign_key "keyword_targets", "keywords"
  add_foreign_key "keyword_targets", "sites"
  add_foreign_key "keywords", "sites", on_delete: :cascade
  add_foreign_key "search_runs", "keywords"
  add_foreign_key "view_series", "keyword_targets"
  add_foreign_key "view_series", "keywords"
  add_foreign_key "view_series", "views"
end

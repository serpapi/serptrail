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

ActiveRecord::Schema[8.1].define(version: 2026_06_15_002040) do
  create_table "chats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "llm_model_id"
    t.datetime "updated_at", null: false
    t.index ["llm_model_id"], name: "index_chats_on_llm_model_id"
  end

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

  create_table "llm_models", force: :cascade do |t|
    t.json "capabilities", default: []
    t.integer "context_window"
    t.datetime "created_at", null: false
    t.string "family"
    t.date "knowledge_cutoff"
    t.integer "max_output_tokens"
    t.json "metadata", default: {}
    t.json "modalities", default: {}
    t.datetime "model_created_at"
    t.string "model_id", null: false
    t.string "name", null: false
    t.json "pricing", default: {}
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["family"], name: "index_llm_models_on_family"
    t.index ["provider", "model_id"], name: "index_llm_models_on_provider_and_model_id", unique: true
    t.index ["provider"], name: "index_llm_models_on_provider"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "cache_creation_tokens"
    t.integer "cached_tokens"
    t.integer "chat_id", null: false
    t.text "content"
    t.json "content_raw"
    t.datetime "created_at", null: false
    t.integer "input_tokens"
    t.integer "llm_model_id"
    t.integer "output_tokens"
    t.string "role", null: false
    t.text "thinking_signature"
    t.text "thinking_text"
    t.integer "thinking_tokens"
    t.integer "tool_call_id"
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["llm_model_id"], name: "index_messages_on_llm_model_id"
    t.index ["role"], name: "index_messages_on_role"
    t.index ["tool_call_id"], name: "index_messages_on_tool_call_id"
  end

  create_table "search_runs", force: :cascade do |t|
    t.datetime "checked_at", null: false
    t.datetime "created_at", null: false
    t.string "engine", default: "google", null: false
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
    t.string "openai_api_key", default: "", null: false
    t.string "serpapi_key", default: "", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tool_calls", force: :cascade do |t|
    t.json "arguments", default: {}
    t.datetime "created_at", null: false
    t.integer "message_id", null: false
    t.string "name", null: false
    t.text "thought_signature"
    t.string "tool_call_id", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_tool_calls_on_message_id"
    t.index ["name"], name: "index_tool_calls_on_name"
    t.index ["tool_call_id"], name: "index_tool_calls_on_tool_call_id", unique: true
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

  add_foreign_key "chats", "llm_models"
  add_foreign_key "checks", "keyword_targets"
  add_foreign_key "checks", "keywords", on_delete: :cascade
  add_foreign_key "checks", "search_runs"
  add_foreign_key "keyword_targets", "keywords"
  add_foreign_key "keyword_targets", "sites"
  add_foreign_key "keywords", "sites", on_delete: :cascade
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "llm_models"
  add_foreign_key "messages", "tool_calls"
  add_foreign_key "search_runs", "keywords"
  add_foreign_key "tool_calls", "messages"
  add_foreign_key "view_series", "keyword_targets"
  add_foreign_key "view_series", "keywords"
  add_foreign_key "view_series", "views"
end

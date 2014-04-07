# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140401072156) do

  create_table "active_admin_comments", force: true do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "admin_users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree

  create_table "catalogues", force: true do |t|
    t.string   "name",                                           null: false
    t.string   "author"
    t.string   "description"
    t.string   "revue_title"
    t.string   "volume"
    t.string   "place"
    t.string   "date"
    t.string   "pages"
    t.string   "wf_audit",    limit: 16, default: "unapproved"
    t.string   "wf_stage",    limit: 16, default: "unpublished"
    t.string   "wf_notes"
    t.integer  "wf_owner",               default: 0
    t.integer  "wf_version",             default: 0
    t.integer  "src_count",              default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "catalogues_sources", id: false, force: true do |t|
    t.integer "catalogue_id"
    t.integer "source_id"
  end

  create_table "libraries", force: true do |t|
    t.string   "siglum",     limit: 32,                         null: false
    t.string   "name"
    t.string   "address"
    t.string   "url"
    t.string   "phone"
    t.string   "email"
    t.string   "wf_audit",   limit: 16, default: "unapproved"
    t.string   "wf_stage",   limit: 16, default: "unpublished"
    t.string   "wf_notes"
    t.integer  "wf_owner",              default: 0
    t.integer  "wf_version",            default: 0
    t.integer  "src_count",             default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "libraries_sources", id: false, force: true do |t|
    t.integer "library_id"
    t.integer "source_id"
  end

  create_table "liturgical_feasts", force: true do |t|
    t.string   "name",                                          null: false
    t.string   "notes"
    t.string   "wf_audit",   limit: 16, default: "unapproved"
    t.string   "wf_stage",   limit: 16, default: "unpublished"
    t.string   "wf_notes"
    t.integer  "wf_owner",              default: 0
    t.integer  "wf_version",            default: 0
    t.integer  "src_count",             default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "liturgical_feasts_sources", id: false, force: true do |t|
    t.integer "liturgical_feast_id"
    t.integer "source_id"
  end

  create_table "people", force: true do |t|
    t.string   "full_name",       limit: 128,                         null: false
    t.string   "full_name_d",     limit: 128
    t.string   "life_dates",      limit: 24
    t.string   "birth_place",     limit: 128
    t.integer  "gender",          limit: 1,   default: 0
    t.integer  "composer",        limit: 1,   default: 0
    t.string   "source"
    t.text     "alternate_names"
    t.text     "alternate_dates"
    t.text     "comments"
    t.string   "wf_audit",        limit: 16,  default: "unapproved"
    t.string   "wf_stage",        limit: 16,  default: "unpublished"
    t.string   "wf_notes"
    t.integer  "wf_owner",                    default: 0
    t.integer  "wf_version",                  default: 0
    t.integer  "src_count",                   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "people_sources", id: false, force: true do |t|
    t.integer "person_id"
    t.integer "source_id"
  end

  create_table "places", force: true do |t|
    t.string   "name",                                          null: false
    t.string   "country"
    t.string   "district"
    t.string   "notes"
    t.string   "wf_audit",   limit: 16, default: "unapproved"
    t.string   "wf_stage",   limit: 16, default: "unpublished"
    t.string   "wf_notes"
    t.integer  "wf_owner",              default: 0
    t.integer  "wf_version",            default: 0
    t.integer  "src_count",             default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "places_sources", id: false, force: true do |t|
    t.integer "place_id"
    t.integer "source_id"
  end

  create_table "sources", id: false, force: true do |t|
    t.integer  "id"
    t.integer  "source_id"
    t.integer  "record_type", limit: 1,   default: 0
    t.string   "std_title"
    t.string   "std_title_d", limit: 128
    t.string   "composer"
    t.string   "composer_d",  limit: 128
    t.string   "title"
    t.string   "title_d",     limit: 128
    t.string   "shelf_mark"
    t.string   "language",    limit: 16
    t.integer  "date_from"
    t.integer  "date_to"
    t.string   "lib_siglums"
    t.text     "source"
    t.string   "wf_audit",    limit: 16,  default: "unapproved"
    t.string   "wf_stage",    limit: 16,  default: "unpublished"
    t.string   "wf_notes"
    t.integer  "wf_owner",                default: 0
    t.integer  "wf_version",              default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sources_standard_terms", id: false, force: true do |t|
    t.integer "standard_term_id"
    t.integer "source_id"
  end

  create_table "sources_standard_titles", id: false, force: true do |t|
    t.integer "standard_title_id"
    t.integer "source_id"
  end

  create_table "sources_works", id: false, force: true do |t|
    t.integer "source_id"
    t.integer "work_id"
  end

  create_table "standard_terms", force: true do |t|
    t.string   "term",                                               null: false
    t.text     "alternate_terms"
    t.text     "notes"
    t.string   "wf_audit",        limit: 16, default: "unapproved"
    t.string   "wf_stage",        limit: 16, default: "unpublished"
    t.string   "wf_notes"
    t.integer  "wf_owner",                   default: 0
    t.integer  "wf_version",                 default: 0
    t.integer  "src_count",                  default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "standard_titles", force: true do |t|
    t.string   "title",                                          null: false
    t.string   "title_d",    limit: 128
    t.text     "notes"
    t.string   "wf_audit",   limit: 16,  default: "unapproved"
    t.string   "wf_stage",   limit: 16,  default: "unpublished"
    t.string   "wf_notes"
    t.integer  "wf_owner",               default: 0
    t.integer  "wf_version",             default: 0
    t.integer  "src_count",              default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "work_incipits", force: true do |t|
    t.integer  "work_id"
    t.string   "nr_work"
    t.string   "movement"
    t.string   "excerpt"
    t.string   "heading"
    t.string   "role"
    t.string   "clef"
    t.string   "instrument_voice"
    t.string   "key_signature"
    t.string   "time_signature"
    t.text     "general_note"
    t.string   "key_mode"
    t.string   "validity"
    t.string   "code"
    t.text     "notation"
    t.text     "text_incipit"
    t.text     "public_note"
    t.string   "incipit_digest"
    t.string   "incipit_human"
    t.string   "wf_audit",         limit: 16, default: "unapproved"
    t.string   "wf_stage",         limit: 16, default: "unpublished"
    t.string   "wf_notes"
    t.integer  "wf_owner",                    default: 0
    t.integer  "wf_version",                  default: 0
    t.integer  "src_count",                   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "works", force: true do |t|
    t.integer  "person_id"
    t.string   "title"
    t.string   "form"
    t.text     "notes"
    t.string   "wf_audit",   limit: 16, default: "unapproved"
    t.string   "wf_stage",   limit: 16, default: "unpublished"
    t.string   "wf_notes"
    t.integer  "wf_owner",              default: 0
    t.integer  "wf_version",            default: 0
    t.integer  "src_count",             default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end

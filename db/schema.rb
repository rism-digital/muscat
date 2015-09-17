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

ActiveRecord::Schema.define(version: 20150824123044) do

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

  create_table "bookmarks", force: true do |t|
    t.integer  "user_id",       null: false
    t.string   "user_type"
    t.string   "document_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "document_type"
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id", using: :btree

  create_table "catalogues", force: true do |t|
    t.string   "name",                                            null: false
    t.string   "author"
    t.string   "description"
    t.string   "revue_title"
    t.string   "volume"
    t.string   "place"
    t.string   "date"
    t.string   "pages"
    t.string   "wf_notes"
    t.integer  "wf_owner",                default: 0
    t.integer  "wf_version",              default: 0
    t.integer  "src_count",               default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "wf_audit",     limit: 16, default: "unapproved"
    t.string   "wf_stage",     limit: 16, default: "unpublished"
    t.text     "marc_source"
    t.integer  "lock_version",            default: 0,             null: false
  end

  add_index "catalogues", ["name"], name: "index_catalogues_on_name", using: :btree
  add_index "catalogues", ["wf_stage"], name: "index_catalogues_on_wf_stage", using: :btree

  create_table "catalogues_sources", id: false, force: true do |t|
    t.integer "catalogue_id"
    t.integer "source_id"
  end

  add_index "catalogues_sources", ["catalogue_id"], name: "catalogue_index", using: :btree
  add_index "catalogues_sources", ["source_id"], name: "manuscript_index", using: :btree

  create_table "do_div_files", force: true do |t|
    t.integer  "do_file_id"
    t.integer  "do_div_id"
    t.integer  "file_order"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "do_div_files", ["do_div_id"], name: "do_div_fk1", using: :btree
  add_index "do_div_files", ["do_file_id"], name: "do_file_fk1", using: :btree

  create_table "do_divs", force: true do |t|
    t.integer  "do_item_id"
    t.string   "title"
    t.integer  "subdiv_id"
    t.string   "subdiv_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "do_divs", ["do_item_id"], name: "do_item_fk1", using: :btree

  create_table "do_file_groups", force: true do |t|
    t.integer  "do_item_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "do_file_groups", ["do_item_id"], name: "do_item_fg_fk1", using: :btree

  create_table "do_files", force: true do |t|
    t.integer  "do_file_group_id"
    t.integer  "do_image_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "do_files", ["do_file_group_id"], name: "do_file_group_fk1", using: :btree
  add_index "do_files", ["do_image_id"], name: "do_image_fk1", using: :btree

  create_table "do_images", force: true do |t|
    t.string   "file_name"
    t.string   "page_name"
    t.string   "label"
    t.text     "notes"
    t.integer  "width"
    t.integer  "height"
    t.text     "exif"
    t.text     "software"
    t.string   "orientation"
    t.integer  "res_number"
    t.integer  "tile_width"
    t.integer  "tile_height"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "file_type",   limit: 16
  end

  add_index "do_images", ["file_type"], name: "type_index", using: :btree

  create_table "do_items", force: true do |t|
    t.string   "item_ext_id", limit: 14
    t.string   "title"
    t.string   "wf_audit",    limit: 16, default: "unapproved"
    t.string   "wf_stage",    limit: 16, default: "unpublished"
    t.string   "wf_notes"
    t.integer  "wf_owner",               default: 0
    t.integer  "wf_version",             default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "item_type"
  end

  add_index "do_items", ["item_type"], name: "type_index", using: :btree

  create_table "folder_items", force: true do |t|
    t.integer  "folder_id"
    t.integer  "item_id"
    t.string   "item_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "folders", force: true do |t|
    t.string   "name"
    t.string   "folder_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "wf_owner"
  end

  create_table "institutions", force: true do |t|
    t.string   "siglum",       limit: 32
    t.string   "name"
    t.string   "address"
    t.string   "url"
    t.string   "phone"
    t.string   "email"
    t.text     "alternates"
    t.text     "notes"
    t.string   "wf_notes"
    t.integer  "wf_owner",                default: 0
    t.integer  "wf_version",              default: 0
    t.integer  "src_count",               default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "wf_audit",     limit: 16, default: "unapproved"
    t.string   "wf_stage",     limit: 16, default: "unpublished"
    t.string   "place"
    t.text     "marc_source"
    t.text     "comments"
    t.integer  "lock_version",            default: 0,             null: false
  end

  add_index "institutions", ["siglum"], name: "index_institutions_on_siglum", using: :btree
  add_index "institutions", ["wf_stage"], name: "index_institutions_on_wf_stage", using: :btree
  add_index "institutions", ["wf_stage"], name: "index_libraries_on_wf_stage", using: :btree

  create_table "institutions_sources", id: false, force: true do |t|
    t.integer "institution_id"
    t.integer "source_id"
  end

  add_index "institutions_sources", ["institution_id"], name: "index_institutions_sources_on_institution_id", using: :btree
  add_index "institutions_sources", ["institution_id"], name: "library_index", using: :btree
  add_index "institutions_sources", ["source_id"], name: "index_institutions_sources_on_source_id", using: :btree
  add_index "institutions_sources", ["source_id"], name: "manuscript_index", using: :btree

  create_table "institutions_workgroups", id: false, force: true do |t|
    t.integer "workgroup_id"
    t.integer "institution_id"
  end

  add_index "institutions_workgroups", ["institution_id"], name: "index_workgroups_institutions_on_institution_id", using: :btree
  add_index "institutions_workgroups", ["workgroup_id"], name: "index_workgroups_institutions_on_workgroup_id", using: :btree

  create_table "liturgical_feasts", force: true do |t|
    t.string   "name",                                            null: false
    t.string   "notes"
    t.string   "wf_notes"
    t.integer  "wf_owner",                default: 0
    t.integer  "wf_version",              default: 0
    t.integer  "src_count",               default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "wf_audit",     limit: 16, default: "unapproved"
    t.string   "wf_stage",     limit: 16, default: "unpublished"
    t.integer  "lock_version",            default: 0,             null: false
  end

  add_index "liturgical_feasts", ["wf_stage"], name: "index_liturgical_feasts_on_wf_stage", using: :btree

  create_table "liturgical_feasts_sources", id: false, force: true do |t|
    t.integer "liturgical_feast_id"
    t.integer "source_id"
  end

  add_index "liturgical_feasts_sources", ["liturgical_feast_id"], name: "liturgical_feast_index", using: :btree
  add_index "liturgical_feasts_sources", ["source_id"], name: "manuscript_index", using: :btree

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
    t.string   "wf_notes"
    t.integer  "wf_owner",                    default: 0
    t.integer  "wf_version",                  default: 0
    t.integer  "src_count",                   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "wf_audit",        limit: 16,  default: "unapproved"
    t.string   "wf_stage",        limit: 16,  default: "unpublished"
    t.text     "marc_source"
    t.integer  "lock_version",                default: 0,             null: false
  end

  add_index "people", ["wf_stage"], name: "index_people_on_wf_stage", using: :btree

  create_table "people_sources", id: false, force: true do |t|
    t.integer "person_id", default: 0, null: false
    t.integer "source_id"
  end

  add_index "people_sources", ["person_id"], name: "person_index", using: :btree
  add_index "people_sources", ["source_id"], name: "manuscript_index", using: :btree

  create_table "places", force: true do |t|
    t.string   "name",                                            null: false
    t.string   "country"
    t.string   "district"
    t.string   "notes"
    t.string   "wf_notes"
    t.integer  "wf_owner",                default: 0
    t.integer  "wf_version",              default: 0
    t.integer  "src_count",               default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "wf_audit",     limit: 16, default: "unapproved"
    t.string   "wf_stage",     limit: 16, default: "unpublished"
    t.integer  "lock_version",            default: 0,             null: false
  end

  add_index "places", ["wf_stage"], name: "index_places_on_wf_stage", using: :btree

  create_table "places_sources", id: false, force: true do |t|
    t.integer "place_id"
    t.integer "source_id"
  end

  add_index "places_sources", ["place_id"], name: "place_index", using: :btree
  add_index "places_sources", ["source_id"], name: "manuscript_index", using: :btree

  create_table "roles", force: true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "searches", force: true do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.string   "user_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id", using: :btree

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "sources", force: true do |t|
    t.integer  "source_id"
    t.string   "std_title"
    t.string   "std_title_d",  limit: 128
    t.string   "composer"
    t.string   "composer_d",   limit: 128
    t.string   "title",        limit: 256
    t.string   "title_d",      limit: 256
    t.string   "shelf_mark"
    t.string   "language",     limit: 16
    t.integer  "date_from"
    t.integer  "date_to"
    t.string   "lib_siglum"
    t.text     "marc_source"
    t.string   "wf_notes"
    t.integer  "wf_owner",                 default: 0
    t.integer  "wf_version",               default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "wf_audit",     limit: 16,  default: "unapproved"
    t.string   "wf_stage",     limit: 16,  default: "unpublished"
    t.integer  "record_type",  limit: 1,   default: 0
    t.integer  "lock_version",             default: 0,             null: false
  end

  add_index "sources", ["source_id"], name: "index_manuscripts_on_manuscript_id", using: :btree
  add_index "sources", ["wf_stage"], name: "index_manuscripts_on_wf_stage", using: :btree

  create_table "sources_standard_terms", id: false, force: true do |t|
    t.integer "standard_term_id"
    t.integer "source_id"
  end

  add_index "sources_standard_terms", ["source_id"], name: "manuscript_index", using: :btree
  add_index "sources_standard_terms", ["standard_term_id"], name: "standard_term_index", using: :btree

  create_table "sources_standard_titles", id: false, force: true do |t|
    t.integer "standard_title_id"
    t.integer "source_id"
  end

  add_index "sources_standard_titles", ["source_id"], name: "manuscript_index", using: :btree
  add_index "sources_standard_titles", ["standard_title_id"], name: "standard_title_index", using: :btree

  create_table "sources_works", force: true do |t|
    t.integer "source_id"
    t.integer "work_id"
  end

  add_index "sources_works", ["source_id"], name: "manuscript_index", using: :btree
  add_index "sources_works", ["work_id"], name: "work_index", using: :btree

  create_table "standard_terms", force: true do |t|
    t.string   "term",                                               null: false
    t.text     "alternate_terms"
    t.text     "notes"
    t.string   "wf_notes"
    t.integer  "wf_owner",                   default: 0
    t.integer  "wf_version",                 default: 0
    t.integer  "src_count",                  default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "wf_audit",        limit: 16, default: "unapproved"
    t.string   "wf_stage",        limit: 16, default: "unpublished"
    t.integer  "lock_version",               default: 0,             null: false
  end

  add_index "standard_terms", ["wf_stage"], name: "index_standard_terms_on_wf_stage", using: :btree

  create_table "standard_titles", force: true do |t|
    t.string   "title",                                            null: false
    t.string   "title_d",      limit: 128
    t.text     "notes"
    t.string   "wf_notes"
    t.integer  "wf_owner",                 default: 0
    t.integer  "wf_version",               default: 0
    t.integer  "src_count",                default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "wf_audit",     limit: 16,  default: "unapproved"
    t.string   "wf_stage",     limit: 16,  default: "unpublished"
    t.integer  "lock_version",             default: 0,             null: false
  end

  add_index "standard_titles", ["wf_stage"], name: "index_standard_titles_on_wf_stage", using: :btree

  create_table "synchronizations", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "name",                   default: "", null: false
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

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "users_roles", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

  create_table "users_workgroups", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "workgroup_id"
  end

  add_index "users_workgroups", ["user_id"], name: "index_workgroups_users_on_user_id", using: :btree
  add_index "users_workgroups", ["workgroup_id"], name: "index_workgroups_users_on_workgroup_id", using: :btree

  create_table "versions", force: true do |t|
    t.string   "item_type",                     null: false
    t.integer  "item_id",                       null: false
    t.string   "event",                         null: false
    t.string   "whodunnit"
    t.text     "object",     limit: 2147483647
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

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

  add_index "work_incipits", ["work_id"], name: "work_incipits_fk1", using: :btree

  create_table "workgroups", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "libpatterns"
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

  add_index "works", ["wf_stage"], name: "index_works_on_wf_stage", using: :btree

end

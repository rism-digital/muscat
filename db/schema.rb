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

ActiveRecord::Schema.define(version: 20171115073728) do

  create_table "DNB", id: false, force: :cascade do |t|
    t.integer "id",     limit: 4,     default: 0, null: false
    t.text    "ext_id", limit: 65535
  end

  create_table "VIAF", id: false, force: :cascade do |t|
    t.integer "id",     limit: 4,          default: 0, null: false
    t.text    "ext_id", limit: 4294967295
  end

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace",     limit: 255
    t.text     "body",          limit: 65535
    t.string   "resource_id",   limit: 255,   null: false
    t.string   "resource_type", limit: 255,   null: false
    t.integer  "author_id",     limit: 4
    t.string   "author_type",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "bookmarks", force: :cascade do |t|
    t.integer  "user_id",       limit: 4,   null: false
    t.string   "user_type",     limit: 255
    t.string   "document_id",   limit: 255
    t.string   "title",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "document_type", limit: 255
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id", using: :btree

  create_table "catalogues", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.string   "author",       limit: 255
    t.string   "description",  limit: 255
    t.string   "revue_title",  limit: 255
    t.string   "volume",       limit: 255
    t.string   "place",        limit: 255
    t.string   "date",         limit: 255
    t.string   "pages",        limit: 255
    t.integer  "wf_audit",     limit: 4,     default: 0
    t.integer  "wf_stage",     limit: 4,     default: 0
    t.string   "wf_notes",     limit: 255
    t.integer  "wf_owner",     limit: 4,     default: 0
    t.integer  "wf_version",   limit: 4,     default: 0
    t.integer  "src_count",    limit: 4,     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "marc_source",  limit: 65535
    t.integer  "lock_version", limit: 4,     default: 0, null: false
  end

  add_index "catalogues", ["name"], name: "index_catalogues_on_name", using: :btree
  add_index "catalogues", ["wf_stage"], name: "index_catalogues_on_wf_stage", using: :btree

  create_table "catalogues_catalogues", id: false, force: :cascade do |t|
    t.integer "catalogue_a_id", limit: 4
    t.integer "catalogue_b_id", limit: 4
  end

  add_index "catalogues_catalogues", ["catalogue_a_id"], name: "index_catalogues_catalogues_on_catalogue_a_id", using: :btree
  add_index "catalogues_catalogues", ["catalogue_b_id"], name: "index_catalogues_catalogues_on_catalogue_b_id", using: :btree

  create_table "catalogues_to_catalogues", id: false, force: :cascade do |t|
    t.integer "catalogue_a_id", limit: 4
    t.integer "catalogue_b_id", limit: 4
  end

  add_index "catalogues_to_catalogues", ["catalogue_a_id"], name: "index_catalogues_to_catalogues_on_catalogue_a_id", using: :btree
  add_index "catalogues_to_catalogues", ["catalogue_b_id"], name: "index_catalogues_to_catalogues_on_catalogue_b_id", using: :btree

  create_table "catalogues_to_institutions", id: false, force: :cascade do |t|
    t.integer "catalogue_id",   limit: 4
    t.integer "institution_id", limit: 4
  end

  add_index "catalogues_to_institutions", ["catalogue_id"], name: "index_catalogues_to_institutions_on_catalogue_id", using: :btree
  add_index "catalogues_to_institutions", ["institution_id"], name: "index_catalogues_to_institutions_on_institution_id", using: :btree

  create_table "catalogues_to_people", id: false, force: :cascade do |t|
    t.integer "catalogue_id", limit: 4
    t.integer "person_id",    limit: 4
  end

  add_index "catalogues_to_people", ["catalogue_id"], name: "index_catalogues_to_people_on_catalogue_id", using: :btree
  add_index "catalogues_to_people", ["person_id"], name: "index_catalogues_to_people_on_person_id", using: :btree

  create_table "catalogues_to_places", id: false, force: :cascade do |t|
    t.integer "place_id",     limit: 4
    t.integer "catalogue_id", limit: 4
  end

  add_index "catalogues_to_places", ["catalogue_id"], name: "index_catalogues_to_places_on_catalogue_id", using: :btree
  add_index "catalogues_to_places", ["place_id"], name: "index_catalogues_to_places_on_place_id", using: :btree

  create_table "catalogues_to_standard_terms", id: false, force: :cascade do |t|
    t.integer "standard_term_id", limit: 4
    t.integer "catalogue_id",     limit: 4
  end

  add_index "catalogues_to_standard_terms", ["catalogue_id"], name: "index_catalogues_to_standard_terms_on_catalogue_id", using: :btree
  add_index "catalogues_to_standard_terms", ["standard_term_id"], name: "index_catalogues_to_standard_terms_on_standard_term_id", using: :btree

  create_table "crono_jobs", force: :cascade do |t|
    t.string   "job_id",            limit: 255,   null: false
    t.text     "log",               limit: 65535
    t.datetime "last_performed_at"
    t.boolean  "healthy"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "crono_jobs", ["job_id"], name: "index_crono_jobs_on_job_id", unique: true, using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",         limit: 4,          default: 0, null: false
    t.integer  "attempts",         limit: 4,          default: 0, null: false
    t.text     "handler",          limit: 65535,                  null: false
    t.text     "last_error",       limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",        limit: 255
    t.string   "queue",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "progress_stage",   limit: 4294967295
    t.integer  "progress_current", limit: 4,          default: 0
    t.integer  "progress_max",     limit: 4,          default: 0
    t.string   "parent_type",      limit: 255
    t.integer  "parent_id",        limit: 4
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "digital_object_links", force: :cascade do |t|
    t.integer  "digital_object_id", limit: 4
    t.integer  "object_link_id",    limit: 4
    t.string   "object_link_type",  limit: 255
    t.integer  "wf_owner",          limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "digital_object_links", ["digital_object_id"], name: "index_digital_object_links_on_digital_object_id", using: :btree
  add_index "digital_object_links", ["object_link_id"], name: "index_digital_object_links_on_object_link_id", using: :btree

  create_table "digital_objects", force: :cascade do |t|
    t.string   "description",             limit: 255
    t.integer  "wf_audit",                limit: 4,   default: 0
    t.integer  "wf_stage",                limit: 4,   default: 0
    t.string   "wf_notes",                limit: 255
    t.integer  "wf_owner",                limit: 4,   default: 0
    t.integer  "wf_version",              limit: 4,   default: 0
    t.integer  "lock_version",            limit: 4,   default: 0, null: false
    t.string   "attachment_file_name",    limit: 255
    t.string   "attachment_content_type", limit: 255
    t.integer  "attachment_file_size",    limit: 4
    t.datetime "attachment_updated_at"
  end

  add_index "digital_objects", ["wf_stage"], name: "index_digital_objects_on_wf_stage", using: :btree

  create_table "dnb", id: false, force: :cascade do |t|
    t.integer "id",       limit: 4,     default: 0,  null: false
    t.string  "provider", limit: 3,     default: "", null: false
    t.text    "ext_id",   limit: 65535
  end

  create_table "do_div_files", force: :cascade do |t|
    t.integer  "do_file_id", limit: 4
    t.integer  "do_div_id",  limit: 4
    t.integer  "file_order", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "do_divs", force: :cascade do |t|
    t.integer  "do_item_id",   limit: 4
    t.string   "title_string", limit: 255
    t.integer  "subdiv_id",    limit: 4
    t.string   "subdiv_type",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "do_file_groups", force: :cascade do |t|
    t.integer  "do_item_id", limit: 4
    t.string   "title",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "do_files", force: :cascade do |t|
    t.integer  "do_file_group_id", limit: 4
    t.integer  "do_image_id",      limit: 4
    t.string   "title",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "do_images", force: :cascade do |t|
    t.string   "file_name",   limit: 255
    t.string   "page_name",   limit: 255
    t.string   "label",       limit: 255
    t.text     "notes",       limit: 65535
    t.integer  "width",       limit: 4
    t.integer  "height",      limit: 4
    t.text     "exif",        limit: 65535
    t.text     "software",    limit: 65535
    t.string   "orientation", limit: 255
    t.integer  "res_number",  limit: 4
    t.integer  "tile_width",  limit: 4
    t.integer  "tile_height", limit: 4
    t.string   "file_type",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "do_images", ["file_type"], name: "index_do_images_on_file_type", using: :btree

  create_table "do_items", force: :cascade do |t|
    t.string   "item_id",    limit: 255
    t.string   "title",      limit: 255
    t.string   "item_type",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "do_items", ["item_id"], name: "index_do_items_on_item_id", using: :btree
  add_index "do_items", ["item_type"], name: "index_do_items_on_item_type", using: :btree

  create_table "folder_items", force: :cascade do |t|
    t.integer  "folder_id",  limit: 4
    t.integer  "item_id",    limit: 4
    t.string   "item_type",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "folder_items", ["folder_id"], name: "index_folder_items_on_folder_id", using: :btree
  add_index "folder_items", ["item_id"], name: "index_folder_items_on_item_id", using: :btree

  create_table "folders", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "folder_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "wf_owner",    limit: 4
  end

  add_index "folders", ["folder_type"], name: "index_folders_on_folder_type", using: :btree
  add_index "folders", ["wf_owner"], name: "index_folders_on_wf_owner", using: :btree

  create_table "holdings", force: :cascade do |t|
    t.integer  "source_id",    limit: 4
    t.string   "lib_siglum",   limit: 255
    t.text     "marc_source",  limit: 65535
    t.integer  "lock_version", limit: 4,     default: 0,             null: false
    t.string   "wf_audit",     limit: 16,    default: "unapproved"
    t.string   "wf_stage",     limit: 16,    default: "unpublished"
    t.string   "wf_notes",     limit: 255
    t.integer  "wf_owner",     limit: 4,     default: 0
    t.integer  "wf_version",   limit: 4,     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "holdings", ["source_id"], name: "index_holdings_on_source_id", using: :btree
  add_index "holdings", ["wf_stage"], name: "index_holdings_on_wf_stage", using: :btree

  create_table "holdings_institutions", id: false, force: :cascade do |t|
    t.integer "holding_id",     limit: 4
    t.integer "institution_id", limit: 4
  end

  add_index "holdings_institutions", ["holding_id"], name: "index_holdings_institutions_on_holding_id", using: :btree
  add_index "holdings_institutions", ["institution_id"], name: "index_holdings_institutions_on_institution_id", using: :btree

  create_table "institutions", force: :cascade do |t|
    t.string   "siglum",       limit: 32
    t.string   "name",         limit: 255
    t.string   "address",      limit: 255
    t.string   "url",          limit: 255
    t.string   "phone",        limit: 255
    t.string   "email",        limit: 255
    t.integer  "wf_audit",     limit: 4,     default: 0
    t.integer  "wf_stage",     limit: 4,     default: 0
    t.string   "wf_notes",     limit: 255
    t.integer  "wf_owner",     limit: 4,     default: 0
    t.integer  "wf_version",   limit: 4,     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "place",        limit: 255
    t.text     "marc_source",  limit: 65535
    t.text     "comments",     limit: 65535
    t.text     "alternates",   limit: 65535
    t.text     "notes",        limit: 65535
    t.integer  "lock_version", limit: 4,     default: 0, null: false
  end

  add_index "institutions", ["siglum"], name: "index_institutions_on_siglum", using: :btree
  add_index "institutions", ["wf_stage"], name: "index_institutions_on_wf_stage", using: :btree

  create_table "institutions_institutions", id: false, force: :cascade do |t|
    t.integer "institution_a_id", limit: 4
    t.integer "institution_b_id", limit: 4
  end

  add_index "institutions_institutions", ["institution_a_id"], name: "index_institutions_institutions_on_institution_a_id", using: :btree
  add_index "institutions_institutions", ["institution_b_id"], name: "index_institutions_institutions_on_institution_b_id", using: :btree

  create_table "institutions_to_catalogues", id: false, force: :cascade do |t|
    t.integer "catalogue_id",   limit: 4
    t.integer "institution_id", limit: 4
  end

  add_index "institutions_to_catalogues", ["catalogue_id"], name: "index_institutions_to_catalogues_on_catalogue_id", using: :btree
  add_index "institutions_to_catalogues", ["institution_id"], name: "index_institutions_to_catalogues_on_institution_id", using: :btree

  create_table "institutions_to_people", id: false, force: :cascade do |t|
    t.integer "institution_id", limit: 4
    t.integer "person_id",      limit: 4
  end

  add_index "institutions_to_people", ["institution_id"], name: "index_institutions_to_people_on_institution_id", using: :btree
  add_index "institutions_to_people", ["person_id"], name: "index_institutions_to_people_on_person_id", using: :btree

  create_table "institutions_to_places", id: false, force: :cascade do |t|
    t.integer "place_id",       limit: 4
    t.integer "institution_id", limit: 4
  end

  add_index "institutions_to_places", ["institution_id"], name: "index_institutions_to_places_on_institution_id", using: :btree
  add_index "institutions_to_places", ["place_id"], name: "index_institutions_to_places_on_place_id", using: :btree

  create_table "institutions_to_standard_terms", id: false, force: :cascade do |t|
    t.integer "standard_term_id", limit: 4
    t.integer "institution_id",   limit: 4
  end

  add_index "institutions_to_standard_terms", ["institution_id"], name: "index_institutions_to_standard_terms_on_institution_id", using: :btree
  add_index "institutions_to_standard_terms", ["standard_term_id"], name: "index_institutions_to_standard_terms_on_standard_term_id", using: :btree

  create_table "institutions_users", id: false, force: :cascade do |t|
    t.integer "user_id",        limit: 4
    t.integer "institution_id", limit: 4
  end

  add_index "institutions_users", ["institution_id"], name: "index_institutions_users_on_institution_id", using: :btree
  add_index "institutions_users", ["user_id"], name: "index_institutions_users_on_user_id", using: :btree

  create_table "institutions_workgroups", id: false, force: :cascade do |t|
    t.integer "workgroup_id",   limit: 4
    t.integer "institution_id", limit: 4
  end

  add_index "institutions_workgroups", ["institution_id"], name: "index_workgroups_institutions_on_institution_id", using: :btree
  add_index "institutions_workgroups", ["workgroup_id"], name: "index_workgroups_institutions_on_workgroup_id", using: :btree

  create_table "liturgical_feasts", force: :cascade do |t|
    t.string   "name",            limit: 255,               null: false
    t.text     "notes",           limit: 65535
    t.integer  "wf_audit",        limit: 4,     default: 0
    t.integer  "wf_stage",        limit: 4,     default: 0
    t.string   "wf_notes",        limit: 255
    t.integer  "wf_owner",        limit: 4,     default: 0
    t.integer  "wf_version",      limit: 4,     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",    limit: 4,     default: 0, null: false
    t.text     "alternate_terms", limit: 65535
    t.text     "sub_topic",       limit: 65535
    t.string   "viaf",            limit: 255
    t.string   "gnd",             limit: 255
  end

  add_index "liturgical_feasts", ["name"], name: "index_liturgical_feasts_on_name", using: :btree
  add_index "liturgical_feasts", ["wf_stage"], name: "index_liturgical_feasts_on_wf_stage", using: :btree

  create_table "people", force: :cascade do |t|
    t.string   "full_name",       limit: 255
    t.string   "full_name_d",     limit: 128
    t.string   "life_dates",      limit: 24
    t.string   "birth_place",     limit: 128
    t.integer  "gender",          limit: 1,     default: 0
    t.integer  "composer",        limit: 1,     default: 0
    t.string   "source",          limit: 255
    t.text     "alternate_names", limit: 65535
    t.text     "alternate_dates", limit: 65535
    t.text     "comments",        limit: 65535
    t.text     "marc_source",     limit: 65535
    t.integer  "wf_audit",        limit: 4,     default: 0
    t.integer  "wf_stage",        limit: 4,     default: 0
    t.string   "wf_notes",        limit: 255
    t.integer  "wf_owner",        limit: 4,     default: 0
    t.integer  "wf_version",      limit: 4,     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",    limit: 4,     default: 0, null: false
  end

  add_index "people", ["full_name"], name: "index_people_on_full_name", using: :btree
  add_index "people", ["wf_stage"], name: "index_people_on_wf_stage", using: :btree

  create_table "people_authorities_links", id: false, force: :cascade do |t|
    t.integer "ID",       limit: 4,     default: 0,  null: false
    t.string  "provider", limit: 4,     default: "", null: false
    t.text    "ext_id",   limit: 65535
  end

  create_table "people_authority_links", id: false, force: :cascade do |t|
    t.integer "ID",       limit: 4,     default: 0,  null: false
    t.string  "provider", limit: 4,     default: "", null: false
    t.text    "ext_id",   limit: 65535
  end

  create_table "people_to_catalogues", id: false, force: :cascade do |t|
    t.integer "person_id",    limit: 4
    t.integer "catalogue_id", limit: 4
  end

  add_index "people_to_catalogues", ["catalogue_id"], name: "index_people_to_catalogues_on_catalogue_id", using: :btree
  add_index "people_to_catalogues", ["person_id"], name: "index_people_to_catalogues_on_person_id", using: :btree

  create_table "people_to_institutions", id: false, force: :cascade do |t|
    t.integer "institution_id", limit: 4
    t.integer "person_id",      limit: 4
  end

  add_index "people_to_institutions", ["institution_id"], name: "index_people_to_institutions_on_institution_id", using: :btree
  add_index "people_to_institutions", ["person_id"], name: "index_people_to_institutions_on_person_id", using: :btree

  create_table "people_to_people", id: false, force: :cascade do |t|
    t.integer "person_a_id", limit: 4
    t.integer "person_b_id", limit: 4
  end

  add_index "people_to_people", ["person_a_id"], name: "index_people_to_people_on_person_a_id", using: :btree
  add_index "people_to_people", ["person_b_id"], name: "index_people_to_people_on_person_b_id", using: :btree

  create_table "people_to_places", id: false, force: :cascade do |t|
    t.integer "place_id",  limit: 4
    t.integer "person_id", limit: 4
  end

  add_index "people_to_places", ["person_id"], name: "index_people_to_places_on_person_id", using: :btree
  add_index "people_to_places", ["place_id"], name: "index_people_to_places_on_place_id", using: :btree

  create_table "person_authorities_link", id: false, force: :cascade do |t|
    t.integer "id",     limit: 4,     default: 0,  null: false
    t.string  "type",   limit: 4,     default: "", null: false
    t.text    "ext_id", limit: 65535
  end

  create_table "person_authorities_links", id: false, force: :cascade do |t|
    t.integer "id",       limit: 4,     default: 0,  null: false
    t.string  "provider", limit: 4,     default: "", null: false
    t.text    "ext_id",   limit: 65535
  end

  create_table "places", force: :cascade do |t|
    t.string   "name",            limit: 255,               null: false
    t.string   "country",         limit: 255
    t.string   "district",        limit: 255
    t.text     "notes",           limit: 65535
    t.integer  "wf_audit",        limit: 4,     default: 0
    t.integer  "wf_stage",        limit: 4,     default: 0
    t.string   "wf_notes",        limit: 255
    t.integer  "wf_owner",        limit: 4,     default: 0
    t.integer  "wf_version",      limit: 4,     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",    limit: 4,     default: 0, null: false
    t.text     "alternate_terms", limit: 65535
    t.text     "topic",           limit: 65535
    t.text     "sub_topic",       limit: 65535
    t.string   "viaf",            limit: 255
    t.string   "gnd",             limit: 255
  end

  add_index "places", ["name"], name: "index_places_on_name", using: :btree
  add_index "places", ["wf_stage"], name: "index_places_on_wf_stage", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.integer  "resource_id",   limit: 4
    t.string   "resource_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "searches", force: :cascade do |t|
    t.text     "query_params", limit: 65535
    t.integer  "user_id",      limit: 4
    t.string   "user_type",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id", using: :btree

  create_table "sources", force: :cascade do |t|
    t.integer  "source_id",    limit: 4
    t.integer  "record_type",  limit: 1,     default: 0
    t.string   "std_title",    limit: 512
    t.string   "std_title_d",  limit: 512
    t.string   "composer",     limit: 255
    t.string   "composer_d",   limit: 255
    t.string   "title",        limit: 256
    t.string   "title_d",      limit: 256
    t.string   "shelf_mark",   limit: 255
    t.string   "language",     limit: 16
    t.integer  "date_from",    limit: 4
    t.integer  "date_to",      limit: 4
    t.string   "lib_siglum",   limit: 255
    t.text     "marc_source",  limit: 65535
    t.integer  "wf_audit",     limit: 4,     default: 0
    t.integer  "wf_stage",     limit: 4,     default: 0
    t.string   "wf_notes",     limit: 255
    t.integer  "wf_owner",     limit: 4,     default: 0
    t.integer  "wf_version",   limit: 4,     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version", limit: 4,     default: 0, null: false
  end

  add_index "sources", ["record_type"], name: "index_sources_on_record_type", using: :btree
  add_index "sources", ["source_id"], name: "index_sources_on_source_id", using: :btree
  add_index "sources", ["std_title"], name: "index_sources_on_std_title", length: {"std_title"=>255}, using: :btree
  add_index "sources", ["std_title_d"], name: "index_sources_on_std_title_d", length: {"std_title_d"=>255}, using: :btree
  add_index "sources", ["wf_stage"], name: "index_sources_on_wf_stage", using: :btree

  create_table "sources_to_catalogues", id: false, force: :cascade do |t|
    t.integer "catalogue_id", limit: 4
    t.integer "source_id",    limit: 4
  end

  add_index "sources_to_catalogues", ["catalogue_id"], name: "index_sources_to_catalogues_on_catalogue_id", using: :btree
  add_index "sources_to_catalogues", ["source_id"], name: "index_sources_to_catalogues_on_source_id", using: :btree

  create_table "sources_to_institutions", id: false, force: :cascade do |t|
    t.integer "institution_id", limit: 4
    t.integer "source_id",      limit: 4
  end

  add_index "sources_to_institutions", ["institution_id"], name: "index_sources_to_institutions_on_institution_id", using: :btree
  add_index "sources_to_institutions", ["source_id"], name: "index_sources_to_institutions_on_source_id", using: :btree

  create_table "sources_to_liturgical_feasts", id: false, force: :cascade do |t|
    t.integer "liturgical_feast_id", limit: 4
    t.integer "source_id",           limit: 4
  end

  add_index "sources_to_liturgical_feasts", ["liturgical_feast_id"], name: "index_sources_to_liturgical_feasts_on_liturgical_feast_id", using: :btree
  add_index "sources_to_liturgical_feasts", ["source_id"], name: "index_sources_to_liturgical_feasts_on_source_id", using: :btree

  create_table "sources_to_people", id: false, force: :cascade do |t|
    t.integer "person_id", limit: 4
    t.integer "source_id", limit: 4
  end

  add_index "sources_to_people", ["person_id"], name: "index_sources_to_people_on_person_id", using: :btree
  add_index "sources_to_people", ["source_id"], name: "index_sources_to_people_on_source_id", using: :btree

  create_table "sources_to_places", id: false, force: :cascade do |t|
    t.integer "place_id",  limit: 4
    t.integer "source_id", limit: 4
  end

  add_index "sources_to_places", ["place_id"], name: "index_sources_to_places_on_place_id", using: :btree
  add_index "sources_to_places", ["source_id"], name: "index_sources_to_places_on_source_id", using: :btree

  create_table "sources_to_sources", id: false, force: :cascade do |t|
    t.integer "source_a_id", limit: 4
    t.integer "source_b_id", limit: 4
  end

  add_index "sources_to_sources", ["source_a_id"], name: "index_sources_to_sources_on_source_a_id", using: :btree
  add_index "sources_to_sources", ["source_b_id"], name: "index_sources_to_sources_on_source_b_id", using: :btree

  create_table "sources_to_standard_terms", id: false, force: :cascade do |t|
    t.integer "standard_term_id", limit: 4
    t.integer "source_id",        limit: 4
  end

  add_index "sources_to_standard_terms", ["source_id"], name: "index_sources_to_standard_terms_on_source_id", using: :btree
  add_index "sources_to_standard_terms", ["standard_term_id"], name: "index_sources_to_standard_terms_on_standard_term_id", using: :btree

  create_table "sources_to_standard_titles", id: false, force: :cascade do |t|
    t.integer "standard_title_id", limit: 4
    t.integer "source_id",         limit: 4
  end

  add_index "sources_to_standard_titles", ["source_id"], name: "index_sources_to_standard_titles_on_source_id", using: :btree
  add_index "sources_to_standard_titles", ["standard_title_id"], name: "index_sources_to_standard_titles_on_standard_title_id", using: :btree

  create_table "sources_to_works", id: false, force: :cascade do |t|
    t.integer "source_id", limit: 4
    t.integer "work_id",   limit: 4
  end

  add_index "sources_to_works", ["source_id"], name: "index_sources_to_works_on_source_id", using: :btree
  add_index "sources_to_works", ["work_id"], name: "index_sources_to_works_on_work_id", using: :btree

  create_table "standard_terms", force: :cascade do |t|
    t.string   "term",            limit: 255,               null: false
    t.text     "alternate_terms", limit: 65535
    t.text     "notes",           limit: 65535
    t.integer  "wf_audit",        limit: 4,     default: 0
    t.integer  "wf_stage",        limit: 4,     default: 0
    t.string   "wf_notes",        limit: 255
    t.integer  "wf_owner",        limit: 4,     default: 0
    t.integer  "wf_version",      limit: 4,     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",    limit: 4,     default: 0, null: false
    t.text     "sub_topic",       limit: 65535
    t.string   "viaf",            limit: 255
    t.string   "gnd",             limit: 255
  end

  add_index "standard_terms", ["term"], name: "index_standard_terms_on_term", using: :btree
  add_index "standard_terms", ["wf_stage"], name: "index_standard_terms_on_wf_stage", using: :btree

  create_table "standard_titles", force: :cascade do |t|
    t.string   "title",           limit: 255,               null: false
    t.string   "title_d",         limit: 128
    t.text     "notes",           limit: 65535
    t.integer  "wf_audit",        limit: 4,     default: 0
    t.integer  "wf_stage",        limit: 4,     default: 0
    t.string   "wf_notes",        limit: 255
    t.integer  "wf_owner",        limit: 4,     default: 0
    t.integer  "wf_version",      limit: 4,     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",    limit: 4,     default: 0, null: false
    t.string   "typus",           limit: 255
    t.text     "alternate_terms", limit: 65535
    t.text     "sub_topic",       limit: 65535
    t.string   "viaf",            limit: 255
    t.string   "gnd",             limit: 255
    t.boolean  "latin"
  end

  add_index "standard_titles", ["title"], name: "index_standard_titles_on_title", using: :btree
  add_index "standard_titles", ["wf_stage"], name: "index_standard_titles_on_wf_stage", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "name",                   limit: 255, default: "", null: false
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "preference_wf_stage",    limit: 4,   default: 1
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id", limit: 4
    t.integer "role_id", limit: 4
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

  create_table "users_workgroups", id: false, force: :cascade do |t|
    t.integer "user_id",      limit: 4
    t.integer "workgroup_id", limit: 4
  end

  add_index "users_workgroups", ["user_id"], name: "index_workgroups_users_on_user_id", using: :btree
  add_index "users_workgroups", ["workgroup_id"], name: "index_workgroups_users_on_workgroup_id", using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  limit: 255,        null: false
    t.integer  "item_id",    limit: 4,          null: false
    t.string   "event",      limit: 255,        null: false
    t.string   "whodunnit",  limit: 255
    t.text     "object",     limit: 4294967295
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

  create_table "viaf", id: false, force: :cascade do |t|
    t.integer "id",       limit: 4,     default: 0,  null: false
    t.string  "provider", limit: 4,     default: "", null: false
    t.text    "ext_id",   limit: 65535
  end

  create_table "work_incipits", force: :cascade do |t|
    t.integer  "work_id",          limit: 4
    t.string   "nr_work",          limit: 255
    t.string   "movement",         limit: 255
    t.string   "excerpt",          limit: 255
    t.string   "heading",          limit: 255
    t.string   "role",             limit: 255
    t.string   "clef",             limit: 255
    t.string   "instrument_voice", limit: 255
    t.string   "key_signature",    limit: 255
    t.string   "time_signature",   limit: 255
    t.text     "general_note",     limit: 65535
    t.string   "key_mode",         limit: 255
    t.string   "validity",         limit: 255
    t.string   "code",             limit: 255
    t.text     "notation",         limit: 65535
    t.text     "text_incipit",     limit: 65535
    t.text     "public_note",      limit: 65535
    t.string   "incipit_digest",   limit: 255
    t.string   "incipit_human",    limit: 255
    t.integer  "wf_audit",         limit: 4,     default: 0
    t.integer  "wf_stage",         limit: 4,     default: 0
    t.string   "wf_notes",         limit: 255
    t.integer  "wf_owner",         limit: 4,     default: 0
    t.integer  "wf_version",       limit: 4,     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "workgroups", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.text     "description", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "libpatterns", limit: 255
  end

  create_table "works", force: :cascade do |t|
    t.integer  "person_id",    limit: 4
    t.string   "title",        limit: 255
    t.string   "form",         limit: 255
    t.text     "notes",        limit: 65535
    t.integer  "wf_audit",     limit: 4,     default: 0
    t.integer  "wf_stage",     limit: 4,     default: 0
    t.string   "wf_notes",     limit: 255
    t.integer  "wf_owner",     limit: 4,     default: 0
    t.integer  "wf_version",   limit: 4,     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "marc_source",  limit: 65535
    t.integer  "lock_version", limit: 4,     default: 0, null: false
  end

  add_index "works", ["title"], name: "index_works_on_title", using: :btree
  add_index "works", ["wf_stage"], name: "index_works_on_wf_stage", using: :btree

end

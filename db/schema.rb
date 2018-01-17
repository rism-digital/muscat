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

  create_table "active_admin_comments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "namespace"
    t.text     "body",          limit: 65535
    t.string   "resource_id",                 null: false
    t.string   "resource_type",               null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree
  end

  create_table "bookmarks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id",       null: false
    t.string   "user_type"
    t.string   "document_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "document_type"
    t.index ["user_id"], name: "index_bookmarks_on_user_id", using: :btree
  end

  create_table "catalogues", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "author"
    t.string   "description"
    t.string   "revue_title"
    t.string   "volume"
    t.string   "place"
    t.string   "date"
    t.string   "pages"
    t.integer  "wf_audit",                   default: 0
    t.integer  "wf_stage",                   default: 0
    t.string   "wf_notes"
    t.integer  "wf_owner",                   default: 0
    t.integer  "wf_version",                 default: 0
    t.integer  "src_count",                  default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "marc_source",  limit: 65535
    t.integer  "lock_version",               default: 0, null: false
    t.index ["name"], name: "index_catalogues_on_name", using: :btree
    t.index ["wf_stage"], name: "index_catalogues_on_wf_stage", using: :btree
  end

  create_table "catalogues_catalogues", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "catalogue_a_id"
    t.integer "catalogue_b_id"
    t.index ["catalogue_a_id"], name: "index_catalogues_catalogues_on_catalogue_a_id", using: :btree
    t.index ["catalogue_b_id"], name: "index_catalogues_catalogues_on_catalogue_b_id", using: :btree
  end

  create_table "catalogues_to_catalogues", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "catalogue_a_id"
    t.integer "catalogue_b_id"
    t.index ["catalogue_a_id"], name: "index_catalogues_to_catalogues_on_catalogue_a_id", using: :btree
    t.index ["catalogue_b_id"], name: "index_catalogues_to_catalogues_on_catalogue_b_id", using: :btree
  end

  create_table "catalogues_to_institutions", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "catalogue_id"
    t.integer "institution_id"
    t.index ["catalogue_id"], name: "index_catalogues_to_institutions_on_catalogue_id", using: :btree
    t.index ["institution_id"], name: "index_catalogues_to_institutions_on_institution_id", using: :btree
  end

  create_table "catalogues_to_people", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "catalogue_id"
    t.integer "person_id"
    t.index ["catalogue_id"], name: "index_catalogues_to_people_on_catalogue_id", using: :btree
    t.index ["person_id"], name: "index_catalogues_to_people_on_person_id", using: :btree
  end

  create_table "catalogues_to_places", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "place_id"
    t.integer "catalogue_id"
    t.index ["catalogue_id"], name: "index_catalogues_to_places_on_catalogue_id", using: :btree
    t.index ["place_id"], name: "index_catalogues_to_places_on_place_id", using: :btree
  end

  create_table "catalogues_to_standard_terms", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "standard_term_id"
    t.integer "catalogue_id"
    t.index ["catalogue_id"], name: "index_catalogues_to_standard_terms_on_catalogue_id", using: :btree
    t.index ["standard_term_id"], name: "index_catalogues_to_standard_terms_on_standard_term_id", using: :btree
  end

  create_table "crono_jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "job_id",                          null: false
    t.text     "log",               limit: 65535
    t.datetime "last_performed_at"
    t.boolean  "healthy"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.index ["job_id"], name: "index_crono_jobs_on_job_id", unique: true, using: :btree
  end

  create_table "delayed_jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "priority",                            default: 0, null: false
    t.integer  "attempts",                            default: 0, null: false
    t.text     "handler",          limit: 65535,                  null: false
    t.text     "last_error",       limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "progress_stage",   limit: 4294967295
    t.integer  "progress_current",                    default: 0
    t.integer  "progress_max",                        default: 0
    t.string   "parent_type"
    t.integer  "parent_id"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree
  end

  create_table "digital_object_links", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "digital_object_id"
    t.integer  "object_link_id"
    t.string   "object_link_type"
    t.integer  "wf_owner"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["digital_object_id"], name: "index_digital_object_links_on_digital_object_id", using: :btree
    t.index ["object_link_id"], name: "index_digital_object_links_on_object_link_id", using: :btree
  end

  create_table "digital_objects", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "description"
    t.integer  "wf_audit",                default: 0
    t.integer  "wf_stage",                default: 0
    t.string   "wf_notes"
    t.integer  "wf_owner",                default: 0
    t.integer  "wf_version",              default: 0
    t.integer  "lock_version",            default: 0, null: false
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.index ["wf_stage"], name: "index_digital_objects_on_wf_stage", using: :btree
  end

  create_table "do_div_files", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "do_file_id"
    t.integer  "do_div_id"
    t.integer  "file_order"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "do_divs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "do_item_id"
    t.string   "title_string"
    t.integer  "subdiv_id"
    t.string   "subdiv_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "do_file_groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "do_item_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "do_files", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "do_file_group_id"
    t.integer  "do_image_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "do_images", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "file_name"
    t.string   "page_name"
    t.string   "label"
    t.text     "notes",       limit: 65535
    t.integer  "width"
    t.integer  "height"
    t.text     "exif",        limit: 65535
    t.text     "software",    limit: 65535
    t.string   "orientation"
    t.integer  "res_number"
    t.integer  "tile_width"
    t.integer  "tile_height"
    t.string   "file_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["file_type"], name: "index_do_images_on_file_type", using: :btree
  end

  create_table "do_items", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "item_id"
    t.string   "title"
    t.string   "item_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["item_id"], name: "index_do_items_on_item_id", using: :btree
    t.index ["item_type"], name: "index_do_items_on_item_type", using: :btree
  end

  create_table "folder_items", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "folder_id"
    t.integer  "item_id"
    t.string   "item_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["folder_id"], name: "index_folder_items_on_folder_id", using: :btree
    t.index ["item_id"], name: "index_folder_items_on_item_id", using: :btree
  end

  create_table "folders", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "folder_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "wf_owner"
    t.index ["folder_type"], name: "index_folders_on_folder_type", using: :btree
    t.index ["wf_owner"], name: "index_folders_on_wf_owner", using: :btree
  end

  create_table "holdings", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "source_id"
    t.string   "lib_siglum"
    t.text     "marc_source",  limit: 65535
    t.integer  "lock_version",               default: 0,             null: false
    t.string   "wf_audit",     limit: 16,    default: "unapproved"
    t.string   "wf_stage",     limit: 16,    default: "unpublished"
    t.string   "wf_notes"
    t.integer  "wf_owner",                   default: 0
    t.integer  "wf_version",                 default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["source_id"], name: "index_holdings_on_source_id", using: :btree
    t.index ["wf_stage"], name: "index_holdings_on_wf_stage", using: :btree
  end

  create_table "holdings_institutions", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "holding_id"
    t.integer "institution_id"
    t.index ["holding_id"], name: "index_holdings_institutions_on_holding_id", using: :btree
    t.index ["institution_id"], name: "index_holdings_institutions_on_institution_id", using: :btree
  end

  create_table "institutions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "siglum",       limit: 32
    t.string   "name"
    t.string   "address"
    t.string   "url"
    t.string   "phone"
    t.string   "email"
    t.integer  "wf_audit",                   default: 0
    t.integer  "wf_stage",                   default: 0
    t.string   "wf_notes"
    t.integer  "wf_owner",                   default: 0
    t.integer  "wf_version",                 default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "place"
    t.text     "marc_source",  limit: 65535
    t.text     "comments",     limit: 65535
    t.text     "alternates",   limit: 65535
    t.text     "notes",        limit: 65535
    t.integer  "lock_version",               default: 0, null: false
    t.index ["siglum"], name: "index_institutions_on_siglum", using: :btree
    t.index ["wf_stage"], name: "index_institutions_on_wf_stage", using: :btree
  end

  create_table "institutions_institutions", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "institution_a_id"
    t.integer "institution_b_id"
    t.index ["institution_a_id"], name: "index_institutions_institutions_on_institution_a_id", using: :btree
    t.index ["institution_b_id"], name: "index_institutions_institutions_on_institution_b_id", using: :btree
  end

  create_table "institutions_to_catalogues", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "catalogue_id"
    t.integer "institution_id"
    t.index ["catalogue_id"], name: "index_institutions_to_catalogues_on_catalogue_id", using: :btree
    t.index ["institution_id"], name: "index_institutions_to_catalogues_on_institution_id", using: :btree
  end

  create_table "institutions_to_people", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "institution_id"
    t.integer "person_id"
    t.index ["institution_id"], name: "index_institutions_to_people_on_institution_id", using: :btree
    t.index ["person_id"], name: "index_institutions_to_people_on_person_id", using: :btree
  end

  create_table "institutions_to_places", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "place_id"
    t.integer "institution_id"
    t.index ["institution_id"], name: "index_institutions_to_places_on_institution_id", using: :btree
    t.index ["place_id"], name: "index_institutions_to_places_on_place_id", using: :btree
  end

  create_table "institutions_to_standard_terms", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "standard_term_id"
    t.integer "institution_id"
    t.index ["institution_id"], name: "index_institutions_to_standard_terms_on_institution_id", using: :btree
    t.index ["standard_term_id"], name: "index_institutions_to_standard_terms_on_standard_term_id", using: :btree
  end

  create_table "institutions_users", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id"
    t.integer "institution_id"
    t.index ["institution_id"], name: "index_institutions_users_on_institution_id", using: :btree
    t.index ["user_id"], name: "index_institutions_users_on_user_id", using: :btree
  end

  create_table "institutions_workgroups", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "workgroup_id"
    t.integer "institution_id"
    t.index ["institution_id"], name: "index_workgroups_institutions_on_institution_id", using: :btree
    t.index ["workgroup_id"], name: "index_workgroups_institutions_on_workgroup_id", using: :btree
  end

  create_table "liturgical_feasts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",                                      null: false
    t.text     "notes",           limit: 65535
    t.integer  "wf_audit",                      default: 0
    t.integer  "wf_stage",                      default: 0
    t.string   "wf_notes"
    t.integer  "wf_owner",                      default: 0
    t.integer  "wf_version",                    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                  default: 0, null: false
    t.text     "alternate_terms", limit: 65535
    t.text     "sub_topic",       limit: 65535
    t.string   "viaf"
    t.string   "gnd"
    t.index ["name"], name: "index_liturgical_feasts_on_name", using: :btree
    t.index ["wf_stage"], name: "index_liturgical_feasts_on_wf_stage", using: :btree
  end

  create_table "people", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "full_name"
    t.string   "full_name_d",     limit: 128
    t.string   "life_dates",      limit: 24
    t.string   "birth_place",     limit: 128
    t.integer  "gender",          limit: 1,     default: 0
    t.integer  "composer",        limit: 1,     default: 0
    t.string   "source"
    t.text     "alternate_names", limit: 65535
    t.text     "alternate_dates", limit: 65535
    t.text     "comments",        limit: 65535
    t.text     "marc_source",     limit: 65535
    t.integer  "wf_audit",                      default: 0
    t.integer  "wf_stage",                      default: 0
    t.string   "wf_notes"
    t.integer  "wf_owner",                      default: 0
    t.integer  "wf_version",                    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                  default: 0, null: false
    t.index ["full_name"], name: "index_people_on_full_name", using: :btree
    t.index ["wf_stage"], name: "index_people_on_wf_stage", using: :btree
  end

  create_table "people_to_catalogues", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "person_id"
    t.integer "catalogue_id"
    t.index ["catalogue_id"], name: "index_people_to_catalogues_on_catalogue_id", using: :btree
    t.index ["person_id"], name: "index_people_to_catalogues_on_person_id", using: :btree
  end

  create_table "people_to_institutions", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "institution_id"
    t.integer "person_id"
    t.index ["institution_id"], name: "index_people_to_institutions_on_institution_id", using: :btree
    t.index ["person_id"], name: "index_people_to_institutions_on_person_id", using: :btree
  end

  create_table "people_to_people", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "person_a_id"
    t.integer "person_b_id"
    t.index ["person_a_id"], name: "index_people_to_people_on_person_a_id", using: :btree
    t.index ["person_b_id"], name: "index_people_to_people_on_person_b_id", using: :btree
  end

  create_table "people_to_places", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "place_id"
    t.integer "person_id"
    t.index ["person_id"], name: "index_people_to_places_on_person_id", using: :btree
    t.index ["place_id"], name: "index_people_to_places_on_place_id", using: :btree
  end

  create_table "places", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",                                      null: false
    t.string   "country"
    t.string   "district"
    t.text     "notes",           limit: 65535
    t.integer  "wf_audit",                      default: 0
    t.integer  "wf_stage",                      default: 0
    t.string   "wf_notes"
    t.integer  "wf_owner",                      default: 0
    t.integer  "wf_version",                    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                  default: 0, null: false
    t.text     "alternate_terms", limit: 65535
    t.text     "topic",           limit: 65535
    t.text     "sub_topic",       limit: 65535
    t.string   "viaf"
    t.string   "gnd"
    t.index ["name"], name: "index_places_on_name", using: :btree
    t.index ["wf_stage"], name: "index_places_on_wf_stage", using: :btree
  end

  create_table "roles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
    t.index ["name"], name: "index_roles_on_name", using: :btree
  end

  create_table "searches", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "query_params", limit: 65535
    t.integer  "user_id"
    t.string   "user_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_searches_on_user_id", using: :btree
  end

  create_table "sources", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "source_id"
    t.integer  "record_type",  limit: 1,     default: 0
    t.string   "std_title",    limit: 512
    t.string   "std_title_d",  limit: 512
    t.string   "composer"
    t.string   "composer_d"
    t.string   "title",        limit: 256
    t.string   "title_d",      limit: 256
    t.string   "shelf_mark"
    t.string   "language",     limit: 16
    t.integer  "date_from"
    t.integer  "date_to"
    t.string   "lib_siglum"
    t.text     "marc_source",  limit: 65535
    t.integer  "wf_audit",                   default: 0
    t.integer  "wf_stage",                   default: 0
    t.string   "wf_notes"
    t.integer  "wf_owner",                   default: 0
    t.integer  "wf_version",                 default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",               default: 0, null: false
    t.index ["record_type"], name: "index_sources_on_record_type", using: :btree
    t.index ["source_id"], name: "index_sources_on_source_id", using: :btree
    t.index ["std_title"], name: "index_sources_on_std_title", length: { std_title: 255 }, using: :btree
    t.index ["std_title_d"], name: "index_sources_on_std_title_d", length: { std_title_d: 255 }, using: :btree
    t.index ["wf_stage"], name: "index_sources_on_wf_stage", using: :btree
  end

  create_table "sources_to_catalogues", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "catalogue_id"
    t.integer "source_id"
    t.index ["catalogue_id"], name: "index_sources_to_catalogues_on_catalogue_id", using: :btree
    t.index ["source_id"], name: "index_sources_to_catalogues_on_source_id", using: :btree
  end

  create_table "sources_to_institutions", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "institution_id"
    t.integer "source_id"
    t.index ["institution_id"], name: "index_sources_to_institutions_on_institution_id", using: :btree
    t.index ["source_id"], name: "index_sources_to_institutions_on_source_id", using: :btree
  end

  create_table "sources_to_liturgical_feasts", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "liturgical_feast_id"
    t.integer "source_id"
    t.index ["liturgical_feast_id"], name: "index_sources_to_liturgical_feasts_on_liturgical_feast_id", using: :btree
    t.index ["source_id"], name: "index_sources_to_liturgical_feasts_on_source_id", using: :btree
  end

  create_table "sources_to_people", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "person_id"
    t.integer "source_id"
    t.index ["person_id"], name: "index_sources_to_people_on_person_id", using: :btree
    t.index ["source_id"], name: "index_sources_to_people_on_source_id", using: :btree
  end

  create_table "sources_to_places", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "place_id"
    t.integer "source_id"
    t.index ["place_id"], name: "index_sources_to_places_on_place_id", using: :btree
    t.index ["source_id"], name: "index_sources_to_places_on_source_id", using: :btree
  end

  create_table "sources_to_sources", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "source_a_id"
    t.integer "source_b_id"
    t.index ["source_a_id"], name: "index_sources_to_sources_on_source_a_id", using: :btree
    t.index ["source_b_id"], name: "index_sources_to_sources_on_source_b_id", using: :btree
  end

  create_table "sources_to_standard_terms", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "standard_term_id"
    t.integer "source_id"
    t.index ["source_id"], name: "index_sources_to_standard_terms_on_source_id", using: :btree
    t.index ["standard_term_id"], name: "index_sources_to_standard_terms_on_standard_term_id", using: :btree
  end

  create_table "sources_to_standard_titles", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "standard_title_id"
    t.integer "source_id"
    t.index ["source_id"], name: "index_sources_to_standard_titles_on_source_id", using: :btree
    t.index ["standard_title_id"], name: "index_sources_to_standard_titles_on_standard_title_id", using: :btree
  end

  create_table "sources_to_works", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "source_id"
    t.integer "work_id"
    t.index ["source_id"], name: "index_sources_to_works_on_source_id", using: :btree
    t.index ["work_id"], name: "index_sources_to_works_on_work_id", using: :btree
  end

  create_table "standard_terms", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "term",                                      null: false
    t.text     "alternate_terms", limit: 65535
    t.text     "notes",           limit: 65535
    t.integer  "wf_audit",                      default: 0
    t.integer  "wf_stage",                      default: 0
    t.string   "wf_notes"
    t.integer  "wf_owner",                      default: 0
    t.integer  "wf_version",                    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                  default: 0, null: false
    t.text     "sub_topic",       limit: 65535
    t.string   "viaf"
    t.string   "gnd"
    t.index ["term"], name: "index_standard_terms_on_term", using: :btree
    t.index ["wf_stage"], name: "index_standard_terms_on_wf_stage", using: :btree
  end

  create_table "standard_titles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "title",                                     null: false
    t.string   "title_d",         limit: 128
    t.text     "notes",           limit: 65535
    t.integer  "wf_audit",                      default: 0
    t.integer  "wf_stage",                      default: 0
    t.string   "wf_notes"
    t.integer  "wf_owner",                      default: 0
    t.integer  "wf_version",                    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                  default: 0, null: false
    t.string   "typus"
    t.text     "alternate_terms", limit: 65535
    t.text     "sub_topic",       limit: 65535
    t.string   "viaf"
    t.string   "gnd"
    t.boolean  "latin"
    t.index ["title"], name: "index_standard_titles_on_title", using: :btree
    t.index ["wf_stage"], name: "index_standard_titles_on_wf_stage", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
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
    t.integer  "preference_wf_stage",    default: 1
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "users_roles", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree
  end

  create_table "users_workgroups", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id"
    t.integer "workgroup_id"
    t.index ["user_id"], name: "index_workgroups_users_on_user_id", using: :btree
    t.index ["workgroup_id"], name: "index_workgroups_users_on_workgroup_id", using: :btree
  end

  create_table "versions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "item_type",                     null: false
    t.integer  "item_id",                       null: false
    t.string   "event",                         null: false
    t.string   "whodunnit"
    t.text     "object",     limit: 4294967295
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  end

  create_table "work_incipits", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
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
    t.text     "general_note",     limit: 65535
    t.string   "key_mode"
    t.string   "validity"
    t.string   "code"
    t.text     "notation",         limit: 65535
    t.text     "text_incipit",     limit: 65535
    t.text     "public_note",      limit: 65535
    t.string   "incipit_digest"
    t.string   "incipit_human"
    t.integer  "wf_audit",                       default: 0
    t.integer  "wf_stage",                       default: 0
    t.string   "wf_notes"
    t.integer  "wf_owner",                       default: 0
    t.integer  "wf_version",                     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "workgroups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.text     "description", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "libpatterns"
  end

  create_table "works", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "person_id"
    t.string   "title"
    t.string   "form"
    t.text     "notes",        limit: 65535
    t.integer  "wf_audit",                   default: 0
    t.integer  "wf_stage",                   default: 0
    t.string   "wf_notes"
    t.integer  "wf_owner",                   default: 0
    t.integer  "wf_version",                 default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "marc_source",  limit: 65535
    t.integer  "lock_version",               default: 0, null: false
    t.index ["title"], name: "index_works_on_title", using: :btree
    t.index ["wf_stage"], name: "index_works_on_wf_stage", using: :btree
  end

end

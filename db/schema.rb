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

ActiveRecord::Schema.define(version: 20180202101517) do

  create_table "active_admin_comments", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_id", null: false
    t.string "resource_type", null: false
    t.integer "author_id"
    t.string "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "bookmarks", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id", null: false
    t.string "user_type"
    t.string "document_id"
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "document_type"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "catalogues", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "author"
    t.string "description"
    t.string "revue_title"
    t.string "volume"
    t.string "place"
    t.string "date"
    t.string "pages"
    t.string "wf_notes"
    t.integer "wf_owner", default: 0
    t.integer "wf_version", default: 0
    t.integer "src_count", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.text "marc_source"
    t.integer "lock_version", default: 0, null: false
    t.index ["name"], name: "index_catalogues_on_name"
    t.index ["wf_stage"], name: "index_catalogues_on_wf_stage"
  end

  create_table "catalogues_catalogues", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "catalogue_a_id"
    t.integer "catalogue_b_id"
    t.index ["catalogue_a_id"], name: "index_catalogues_catalogues_on_catalogue_a_id"
    t.index ["catalogue_b_id"], name: "index_catalogues_catalogues_on_catalogue_b_id"
  end

  create_table "catalogues_to_catalogues", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "catalogue_a_id"
    t.integer "catalogue_b_id"
    t.index ["catalogue_a_id"], name: "index_catalogues_to_catalogues_on_catalogue_a_id"
    t.index ["catalogue_b_id"], name: "index_catalogues_to_catalogues_on_catalogue_b_id"
  end

  create_table "catalogues_to_institutions", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "catalogue_id"
    t.integer "institution_id"
    t.index ["catalogue_id"], name: "index_catalogues_to_institutions_on_catalogue_id"
    t.index ["institution_id"], name: "index_catalogues_to_institutions_on_institution_id"
  end

  create_table "catalogues_to_people", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "catalogue_id"
    t.integer "person_id"
    t.index ["catalogue_id"], name: "index_catalogues_to_people_on_catalogue_id"
    t.index ["person_id"], name: "index_catalogues_to_people_on_person_id"
  end

  create_table "catalogues_to_places", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "place_id"
    t.integer "catalogue_id"
    t.index ["catalogue_id"], name: "index_catalogues_to_places_on_catalogue_id"
    t.index ["place_id"], name: "index_catalogues_to_places_on_place_id"
  end

  create_table "catalogues_to_standard_terms", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "standard_term_id"
    t.integer "catalogue_id"
    t.index ["catalogue_id"], name: "index_catalogues_to_standard_terms_on_catalogue_id"
    t.index ["standard_term_id"], name: "index_catalogues_to_standard_terms_on_standard_term_id"
  end

  create_table "crono_jobs", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "job_id", null: false
    t.text "log"
    t.datetime "last_performed_at"
    t.boolean "healthy"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_crono_jobs_on_job_id", unique: true
  end

  create_table "delayed_jobs", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "progress_stage"
    t.integer "progress_current", default: 0
    t.integer "progress_max", default: 0
    t.string "parent_type"
    t.integer "parent_id"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "digital_object_links", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "digital_object_id"
    t.integer "object_link_id"
    t.string "object_link_type"
    t.integer "wf_owner"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["digital_object_id"], name: "index_digital_object_links_on_digital_object_id"
    t.index ["object_link_id"], name: "index_digital_object_links_on_object_link_id"
  end

  create_table "digital_objects", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "description"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.string "wf_notes"
    t.integer "wf_owner", default: 0
    t.integer "wf_version", default: 0
    t.integer "lock_version", default: 0, null: false
    t.string "attachment_file_name"
    t.string "attachment_content_type"
    t.integer "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.index ["wf_stage"], name: "index_digital_objects_on_wf_stage"
  end

  create_table "do_div_files", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "do_file_id"
    t.integer "do_div_id"
    t.integer "file_order"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["do_div_id"], name: "do_div_fk1"
    t.index ["do_file_id"], name: "do_file_fk1"
  end

  create_table "do_divs", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "do_item_id"
    t.string "title"
    t.integer "subdiv_id"
    t.string "subdiv_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["do_item_id"], name: "do_item_fk1"
  end

  create_table "do_file_groups", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "do_item_id"
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["do_item_id"], name: "do_item_fg_fk1"
  end

  create_table "do_files", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "do_file_group_id"
    t.integer "do_image_id"
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["do_file_group_id"], name: "do_file_group_fk1"
    t.index ["do_image_id"], name: "do_image_fk1"
  end

  create_table "do_images", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "file_name"
    t.string "page_name"
    t.string "label"
    t.text "notes"
    t.integer "width"
    t.integer "height"
    t.text "exif"
    t.text "software"
    t.string "orientation"
    t.integer "res_number"
    t.integer "tile_width"
    t.integer "tile_height"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "file_type", limit: 16
    t.index ["file_type"], name: "type_index"
  end

  create_table "do_items", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "item_ext_id", limit: 14
    t.string "title"
    t.string "wf_audit", limit: 16, default: "unapproved"
    t.string "wf_stage", limit: 16, default: "unpublished"
    t.string "wf_notes"
    t.integer "wf_owner", default: 0
    t.integer "wf_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "item_type"
    t.index ["item_type"], name: "type_index"
  end

  create_table "folder_items", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "folder_id"
    t.integer "item_id"
    t.string "item_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["folder_id"], name: "index_folder_items_on_folder_id"
    t.index ["item_id"], name: "index_folder_items_on_item_id"
  end

  create_table "folders", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "folder_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "wf_owner"
    t.index ["folder_type"], name: "index_folders_on_folder_type"
    t.index ["wf_owner"], name: "index_folders_on_wf_owner"
  end

  create_table "holdings", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "source_id"
    t.string "lib_siglum"
    t.text "marc_source"
    t.integer "lock_version", default: 0, null: false
    t.string "wf_audit", limit: 16, default: "unapproved"
    t.string "wf_stage", limit: 16, default: "unpublished"
    t.string "wf_notes"
    t.integer "wf_owner", default: 0
    t.integer "wf_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["source_id"], name: "index_holdings_on_source_id"
    t.index ["wf_stage"], name: "index_holdings_on_wf_stage"
  end

  create_table "holdings_institutions", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "holding_id"
    t.integer "institution_id"
    t.index ["holding_id"], name: "index_holdings_institutions_on_holding_id"
    t.index ["institution_id"], name: "index_holdings_institutions_on_institution_id"
  end

  create_table "institutions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "siglum", limit: 32
    t.string "name"
    t.string "address"
    t.string "url"
    t.string "phone"
    t.string "email"
    t.text "alternates"
    t.text "notes"
    t.string "wf_notes"
    t.integer "wf_owner", default: 0
    t.integer "wf_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.string "place"
    t.text "marc_source"
    t.text "comments"
    t.integer "lock_version", default: 0, null: false
    t.index ["siglum"], name: "index_institutions_on_siglum"
    t.index ["wf_stage"], name: "index_institutions_on_wf_stage"
    t.index ["wf_stage"], name: "index_libraries_on_wf_stage"
  end

  create_table "institutions_institutions", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "institution_a_id"
    t.integer "institution_b_id"
    t.index ["institution_a_id"], name: "index_institutions_institutions_on_institution_a_id"
    t.index ["institution_b_id"], name: "index_institutions_institutions_on_institution_b_id"
  end

  create_table "institutions_to_catalogues", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "catalogue_id"
    t.integer "institution_id"
    t.index ["catalogue_id"], name: "index_institutions_to_catalogues_on_catalogue_id"
    t.index ["institution_id"], name: "index_institutions_to_catalogues_on_institution_id"
  end

  create_table "institutions_to_people", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "institution_id"
    t.integer "person_id"
    t.index ["institution_id"], name: "index_institutions_to_people_on_institution_id"
    t.index ["person_id"], name: "index_institutions_to_people_on_person_id"
  end

  create_table "institutions_to_places", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "place_id"
    t.integer "institution_id"
    t.index ["institution_id"], name: "index_institutions_to_places_on_institution_id"
    t.index ["place_id"], name: "index_institutions_to_places_on_place_id"
  end

  create_table "institutions_to_standard_terms", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "standard_term_id"
    t.integer "institution_id"
    t.index ["institution_id"], name: "index_institutions_to_standard_terms_on_institution_id"
    t.index ["standard_term_id"], name: "index_institutions_to_standard_terms_on_standard_term_id"
  end

  create_table "institutions_workgroups", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "workgroup_id"
    t.integer "institution_id"
    t.index ["institution_id"], name: "index_workgroups_institutions_on_institution_id"
    t.index ["workgroup_id"], name: "index_workgroups_institutions_on_workgroup_id"
  end

  create_table "liturgical_feasts", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.text "notes"
    t.string "wf_notes"
    t.integer "wf_owner", default: 0
    t.integer "wf_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.integer "lock_version", default: 0, null: false
    t.text "alternate_terms"
    t.text "sub_topic"
    t.string "viaf"
    t.string "gnd"
    t.index ["wf_stage"], name: "index_liturgical_feasts_on_wf_stage"
  end

  create_table "people", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "full_name"
    t.string "full_name_d", limit: 128
    t.string "life_dates", limit: 24
    t.string "birth_place", limit: 128
    t.integer "gender", limit: 1, default: 0
    t.integer "composer", limit: 1, default: 0
    t.string "source"
    t.text "alternate_names"
    t.text "alternate_dates"
    t.text "comments"
    t.string "wf_notes"
    t.integer "wf_owner", default: 0
    t.integer "wf_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.text "marc_source"
    t.integer "lock_version", default: 0, null: false
    t.index ["wf_stage"], name: "index_people_on_wf_stage"
  end

  create_table "people_to_catalogues", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "person_id"
    t.integer "catalogue_id"
    t.index ["catalogue_id"], name: "index_people_to_catalogues_on_catalogue_id"
    t.index ["person_id"], name: "index_people_to_catalogues_on_person_id"
  end

  create_table "people_to_institutions", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "institution_id"
    t.integer "person_id"
    t.index ["institution_id"], name: "index_people_to_institutions_on_institution_id"
    t.index ["person_id"], name: "index_people_to_institutions_on_person_id"
  end

  create_table "people_to_people", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "person_a_id"
    t.integer "person_b_id"
    t.index ["person_a_id"], name: "index_people_to_people_on_person_a_id"
    t.index ["person_b_id"], name: "index_people_to_people_on_person_b_id"
  end

  create_table "people_to_places", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "place_id"
    t.integer "person_id"
    t.index ["person_id"], name: "index_people_to_places_on_person_id"
    t.index ["place_id"], name: "index_people_to_places_on_place_id"
  end

  create_table "places", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.string "country"
    t.string "district"
    t.text "notes"
    t.string "wf_notes"
    t.integer "wf_owner", default: 0
    t.integer "wf_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.integer "lock_version", default: 0, null: false
    t.text "alternate_terms"
    t.text "topic"
    t.text "sub_topic"
    t.string "viaf"
    t.string "gnd"
    t.index ["wf_stage"], name: "index_places_on_wf_stage"
  end

  create_table "roles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "searches", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text "query_params"
    t.integer "user_id"
    t.string "user_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "sessions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "sources", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "source_id"
    t.string "std_title", limit: 512
    t.string "std_title_d", limit: 512
    t.string "composer"
    t.string "composer_d", limit: 128
    t.string "title", limit: 256
    t.string "title_d", limit: 256
    t.string "shelf_mark"
    t.string "language", limit: 16
    t.integer "date_from"
    t.integer "date_to"
    t.string "lib_siglum"
    t.text "marc_source"
    t.string "wf_notes"
    t.integer "wf_owner", default: 0
    t.integer "wf_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.integer "record_type", limit: 1, default: 0
    t.integer "lock_version", default: 0, null: false
    t.index ["source_id"], name: "index_manuscripts_on_manuscript_id"
    t.index ["std_title"], name: "index_sources_on_std_title", length: { std_title: 255 }
    t.index ["std_title_d"], name: "index_sources_on_std_title_d", length: { std_title_d: 255 }
    t.index ["wf_stage"], name: "index_manuscripts_on_wf_stage"
  end

  create_table "sources_to_catalogues", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "catalogue_id"
    t.integer "source_id"
    t.index ["catalogue_id"], name: "catalogue_index"
    t.index ["source_id"], name: "manuscript_index"
  end

  create_table "sources_to_institutions", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "institution_id"
    t.integer "source_id"
    t.index ["institution_id"], name: "index_sources_to_institutions_on_institution_id"
    t.index ["institution_id"], name: "library_index"
    t.index ["source_id"], name: "index_sources_to_institutions_on_source_id"
    t.index ["source_id"], name: "manuscript_index"
  end

  create_table "sources_to_liturgical_feasts", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "liturgical_feast_id"
    t.integer "source_id"
    t.index ["liturgical_feast_id"], name: "liturgical_feast_index"
    t.index ["source_id"], name: "manuscript_index"
  end

  create_table "sources_to_people", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "person_id", default: 0, null: false
    t.integer "source_id"
    t.index ["person_id"], name: "person_index"
    t.index ["source_id"], name: "manuscript_index"
  end

  create_table "sources_to_places", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "place_id"
    t.integer "source_id"
    t.index ["place_id"], name: "place_index"
    t.index ["source_id"], name: "manuscript_index"
  end

  create_table "sources_to_sources", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "source_a_id"
    t.integer "source_b_id"
    t.index ["source_a_id"], name: "index_sources_to_sources_on_source_a_id"
    t.index ["source_b_id"], name: "index_sources_to_sources_on_source_b_id"
  end

  create_table "sources_to_standard_terms", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "standard_term_id"
    t.integer "source_id"
    t.index ["source_id"], name: "manuscript_index"
    t.index ["standard_term_id"], name: "standard_term_index"
  end

  create_table "sources_to_standard_titles", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "standard_title_id"
    t.integer "source_id"
    t.index ["source_id"], name: "manuscript_index"
    t.index ["standard_title_id"], name: "standard_title_index"
  end

  create_table "sources_to_works", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "source_id"
    t.integer "work_id"
    t.index ["source_id"], name: "manuscript_index"
    t.index ["work_id"], name: "work_index"
  end

  create_table "standard_terms", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "term", null: false
    t.text "alternate_terms"
    t.text "notes"
    t.string "wf_notes"
    t.integer "wf_owner", default: 0
    t.integer "wf_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.integer "lock_version", default: 0, null: false
    t.text "sub_topic"
    t.string "viaf"
    t.string "gnd"
    t.index ["wf_stage"], name: "index_standard_terms_on_wf_stage"
  end

  create_table "standard_titles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "title", null: false
    t.string "title_d", limit: 128
    t.text "notes"
    t.string "wf_notes"
    t.integer "wf_owner", default: 0
    t.integer "wf_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.integer "lock_version", default: 0, null: false
    t.string "typus"
    t.text "alternate_terms"
    t.text "sub_topic"
    t.string "viaf"
    t.string "gnd"
    t.boolean "latin"
    t.index ["wf_stage"], name: "index_standard_titles_on_wf_stage"
  end

  create_table "synchronizations", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", default: "", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "preference_wf_stage", default: 1
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
  end

  create_table "users_workgroups", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id"
    t.integer "workgroup_id"
    t.index ["user_id"], name: "index_workgroups_users_on_user_id"
    t.index ["workgroup_id"], name: "index_workgroups_users_on_workgroup_id"
  end

  create_table "versions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", limit: 4294967295
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "work_incipits", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "work_id"
    t.string "nr_work"
    t.string "movement"
    t.string "excerpt"
    t.string "heading"
    t.string "role"
    t.string "clef"
    t.string "instrument_voice"
    t.string "key_signature"
    t.string "time_signature"
    t.text "general_note"
    t.string "key_mode"
    t.string "validity"
    t.string "code"
    t.text "notation"
    t.text "text_incipit"
    t.text "public_note"
    t.string "incipit_digest"
    t.string "incipit_human"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.string "wf_notes"
    t.integer "wf_owner", default: 0
    t.integer "wf_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["work_id"], name: "work_incipits_fk1"
  end

  create_table "workgroups", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "libpatterns"
  end

  create_table "works", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "person_id"
    t.string "title"
    t.string "form"
    t.text "notes"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.string "wf_notes"
    t.integer "wf_owner", default: 0
    t.integer "wf_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "marc_source"
    t.integer "lock_version", default: 0, null: false
    t.index ["wf_stage"], name: "index_works_on_wf_stage"
  end

  add_foreign_key "do_div_files", "do_divs", name: "do_div_fk1", on_update: :cascade
  add_foreign_key "do_div_files", "do_files", name: "do_file_fk1", on_update: :cascade
  add_foreign_key "do_divs", "do_items", name: "do_item_fk1", on_update: :cascade
  add_foreign_key "do_file_groups", "do_items", name: "do_item_fg_fk1", on_update: :cascade
  add_foreign_key "do_files", "do_file_groups", name: "do_file_group_fk1", on_update: :cascade
  add_foreign_key "do_files", "do_images", name: "do_image_fk1", on_update: :cascade
  add_foreign_key "sources_to_catalogues", "catalogues", name: "catalogues_sources_fk2", on_update: :cascade
  add_foreign_key "sources_to_catalogues", "sources", name: "catalogues_manuscripts_fk1", on_update: :cascade
  add_foreign_key "sources_to_institutions", "institutions", name: "institutions_sources_fk2", on_update: :cascade
  add_foreign_key "sources_to_institutions", "sources", name: "institutions_sources_fk1", on_update: :cascade
  add_foreign_key "sources_to_liturgical_feasts", "liturgical_feasts", name: "liturgical_feasts_sources_fk2", on_update: :cascade
  add_foreign_key "sources_to_liturgical_feasts", "sources", name: "liturgical_feasts_sources_fk1", on_update: :cascade
  add_foreign_key "sources_to_people", "people", name: "people_sources_fk2", on_update: :cascade
  add_foreign_key "sources_to_people", "sources", name: "people_sources_fk1", on_update: :cascade
  add_foreign_key "sources_to_places", "places", name: "places_sources_fk2", on_update: :cascade
  add_foreign_key "sources_to_places", "sources", name: "places_sources_fk1", on_update: :cascade
  add_foreign_key "sources_to_standard_terms", "sources", name: "sources_standard_terms_fk1", on_update: :cascade
  add_foreign_key "sources_to_standard_terms", "standard_terms", name: "sources_standard_terms_fk2", on_update: :cascade
  add_foreign_key "sources_to_standard_titles", "sources", name: "sources_standard_titles_fk1", on_update: :cascade
  add_foreign_key "sources_to_standard_titles", "standard_titles", name: "sources_standard_titles_fk2", on_update: :cascade
  add_foreign_key "sources_to_works", "sources", name: "sources_works_fk1", on_update: :cascade
  add_foreign_key "sources_to_works", "works", name: "sources_works_fk2", on_update: :cascade
  add_foreign_key "work_incipits", "works", name: "work_incipits_fk1", on_update: :cascade
end

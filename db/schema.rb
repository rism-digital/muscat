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

ActiveRecord::Schema[7.0].define(version: 2024_01_24_133559) do
  create_table "active_admin_comments", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_id", null: false
    t.string "resource_type", null: false
    t.integer "author_id"
    t.string "author_type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "authorization_tokens", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "token"
    t.string "comment"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delayed_jobs", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "progress_stage", size: :long
    t.integer "progress_current", default: 0
    t.integer "progress_max", default: 0
    t.string "parent_type"
    t.integer "parent_id"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "digital_object_links", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "digital_object_id"
    t.integer "object_link_id"
    t.string "object_link_type"
    t.integer "wf_owner"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["digital_object_id"], name: "index_digital_object_links_on_digital_object_id"
    t.index ["object_link_id"], name: "index_digital_object_links_on_object_link_id"
  end

  create_table "digital_objects", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "description"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.integer "wf_owner", default: 0
    t.integer "lock_version", default: 0, null: false
    t.string "attachment_file_name"
    t.string "attachment_content_type"
    t.integer "attachment_file_size"
    t.datetime "attachment_updated_at", precision: nil
    t.integer "attachment_type", default: 0
    t.index ["wf_stage"], name: "index_digital_objects_on_wf_stage"
  end

  create_table "folder_items", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "folder_id"
    t.integer "item_id"
    t.string "item_type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["folder_id"], name: "index_folder_items_on_folder_id"
    t.index ["item_id"], name: "index_folder_items_on_item_id"
  end

  create_table "folders", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "folder_type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "wf_owner"
    t.datetime "delete_date", precision: nil
    t.index ["folder_type"], name: "index_folders_on_folder_type"
    t.index ["wf_owner"], name: "index_folders_on_wf_owner"
  end

  create_table "holdings", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "source_id"
    t.string "lib_siglum", limit: 32, collation: "utf8mb4_0900_as_cs"
    t.text "marc_source"
    t.integer "lock_version", default: 0, null: false
    t.integer "wf_audit"
    t.integer "wf_stage"
    t.integer "wf_owner", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "collection_id"
    t.index ["collection_id"], name: "index_holdings_on_collection_id"
    t.index ["lib_siglum"], name: "index_holdings_on_lib_siglum"
    t.index ["source_id"], name: "index_holdings_on_source_id"
    t.index ["wf_stage"], name: "index_holdings_on_wf_stage"
  end

  create_table "holdings_to_institutions", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "holding_id"
    t.integer "institution_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["holding_id"], name: "index_holdings_to_institutions_on_holding_id"
    t.index ["institution_id"], name: "index_holdings_to_institutions_on_institution_id"
    t.index ["marc_tag", "relator_code", "holding_id", "institution_id"], name: "unique_records", unique: true
  end

  create_table "holdings_to_people", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "person_id"
    t.integer "holding_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["holding_id"], name: "index_holdings_to_people_on_holding_id"
    t.index ["marc_tag", "relator_code", "holding_id", "person_id"], name: "unique_records", unique: true
    t.index ["person_id"], name: "index_holdings_to_people_on_person_id"
  end

  create_table "holdings_to_places", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "place_id"
    t.integer "holding_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["holding_id"], name: "index_holdings_to_places_on_holding_id"
    t.index ["marc_tag", "relator_code", "holding_id", "place_id"], name: "unique_records", unique: true
    t.index ["place_id"], name: "index_holdings_to_places_on_place_id"
  end

  create_table "holdings_to_publications", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "publication_id"
    t.integer "holding_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["holding_id"], name: "index_holdings_to_publications_on_holding_id"
    t.index ["marc_tag", "relator_code", "holding_id", "publication_id"], name: "unique_records", unique: true
    t.index ["publication_id"], name: "index_holdings_to_publications_on_publication_id"
  end

  create_table "institutions", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "siglum", limit: 32, collation: "utf8mb4_0900_as_cs"
    t.string "full_name"
    t.string "address"
    t.string "url"
    t.string "phone"
    t.string "email"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.integer "wf_owner", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "place"
    t.text "marc_source"
    t.text "comments"
    t.text "alternates"
    t.text "notes"
    t.integer "lock_version", default: 0, null: false
    t.string "corporate_name"
    t.string "subordinate_unit"
    t.index ["siglum"], name: "index_institutions_on_siglum"
    t.index ["wf_stage"], name: "index_institutions_on_wf_stage"
  end

  create_table "institutions_to_institutions", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "institution_a_id"
    t.integer "institution_b_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["institution_a_id"], name: "index_institutions_to_institutions_on_institution_a_id"
    t.index ["institution_b_id"], name: "index_institutions_to_institutions_on_institution_b_id"
    t.index ["marc_tag", "relator_code", "institution_a_id", "institution_b_id"], name: "unique_records", unique: true
  end

  create_table "institutions_to_people", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "institution_id"
    t.integer "person_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["institution_id"], name: "index_institutions_to_people_on_institution_id"
    t.index ["marc_tag", "relator_code", "institution_id", "person_id"], name: "unique_records", unique: true
    t.index ["person_id"], name: "index_institutions_to_people_on_person_id"
  end

  create_table "institutions_to_places", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "place_id"
    t.integer "institution_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["institution_id"], name: "index_institutions_to_places_on_institution_id"
    t.index ["marc_tag", "relator_code", "institution_id", "place_id"], name: "unique_records", unique: true
    t.index ["place_id"], name: "index_institutions_to_places_on_place_id"
  end

  create_table "institutions_to_publications", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "publication_id"
    t.integer "institution_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["institution_id"], name: "index_institutions_to_publications_on_institution_id"
    t.index ["marc_tag", "relator_code", "institution_id", "publication_id"], name: "unique_records", unique: true
    t.index ["publication_id"], name: "index_institutions_to_publications_on_publication_id"
  end

  create_table "institutions_workgroups", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.integer "workgroup_id"
    t.integer "institution_id"
    t.index ["institution_id"], name: "index_workgroups_institutions_on_institution_id"
    t.index ["workgroup_id"], name: "index_workgroups_institutions_on_workgroup_id"
  end

  create_table "liturgical_feasts", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.text "notes"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.integer "wf_owner", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "lock_version", default: 0, null: false
    t.text "alternate_terms"
    t.text "sub_topic"
    t.string "viaf"
    t.string "gnd"
    t.index ["name"], name: "index_liturgical_feasts_on_name"
    t.index ["wf_stage"], name: "index_liturgical_feasts_on_wf_stage"
  end

  create_table "people", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "full_name"
    t.string "full_name_d", limit: 128
    t.string "life_dates", limit: 24
    t.string "birth_place", limit: 128
    t.integer "gender", limit: 1, default: 0
    t.integer "composer", limit: 1, default: 0
    t.string "source"
    t.text "alternate_names"
    t.text "alternate_dates"
    t.text "marc_source"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.integer "wf_owner", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "lock_version", default: 0, null: false
    t.index ["full_name"], name: "index_people_on_full_name"
    t.index ["wf_stage"], name: "index_people_on_wf_stage"
  end

  create_table "people_to_institutions", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "institution_id"
    t.integer "person_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["institution_id"], name: "index_people_to_institutions_on_institution_id"
    t.index ["marc_tag", "relator_code", "person_id", "institution_id"], name: "unique_records", unique: true
    t.index ["person_id"], name: "index_people_to_institutions_on_person_id"
  end

  create_table "people_to_people", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "person_a_id"
    t.integer "person_b_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "person_a_id", "person_b_id"], name: "unique_records", unique: true
    t.index ["person_a_id"], name: "index_people_to_people_on_person_a_id"
    t.index ["person_b_id"], name: "index_people_to_people_on_person_b_id"
  end

  create_table "people_to_places", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "place_id"
    t.integer "person_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "person_id", "place_id"], name: "unique_records_people_to_places", unique: true
    t.index ["person_id"], name: "index_people_to_places_on_person_id"
    t.index ["place_id"], name: "index_people_to_places_on_place_id"
  end

  create_table "people_to_publications", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "person_id"
    t.integer "publication_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "person_id", "publication_id"], name: "unique_records", unique: true
    t.index ["person_id"], name: "index_people_to_publications_on_person_id"
    t.index ["publication_id"], name: "index_people_to_publications_on_publication_id"
  end

  create_table "places", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.string "country"
    t.string "district"
    t.text "notes"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.integer "wf_owner", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "lock_version", default: 0, null: false
    t.text "alternate_terms"
    t.text "topic"
    t.text "sub_topic"
    t.string "viaf"
    t.string "gnd"
    t.index ["name"], name: "index_places_on_name"
    t.index ["wf_stage"], name: "index_places_on_wf_stage"
  end

  create_table "publications", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "short_name"
    t.string "author"
    t.string "title"
    t.string "journal"
    t.string "volume"
    t.string "place"
    t.string "date"
    t.string "pages"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.integer "wf_owner", default: 0
    t.integer "src_count", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "marc_source", size: :medium
    t.integer "lock_version", default: 0, null: false
    t.boolean "work_catalogue", default: false, null: false
    t.index ["created_at"], name: "index_publications_on_created_at"
    t.index ["short_name"], name: "index_publications_on_short_name"
    t.index ["updated_at"], name: "index_publications_on_updated_at"
    t.index ["wf_stage"], name: "index_publications_on_wf_stage"
  end

  create_table "publications_to_institutions", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "publication_id"
    t.integer "institution_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["institution_id"], name: "index_publications_to_institutions_on_institution_id"
    t.index ["marc_tag", "relator_code", "publication_id", "institution_id"], name: "unique_records", unique: true
    t.index ["publication_id"], name: "index_publications_to_institutions_on_publication_id"
  end

  create_table "publications_to_people", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "publication_id"
    t.integer "person_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "publication_id", "person_id"], name: "unique_records", unique: true
    t.index ["person_id"], name: "index_publications_to_people_on_person_id"
    t.index ["publication_id"], name: "index_publications_to_people_on_publication_id"
  end

  create_table "publications_to_places", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "place_id"
    t.integer "publication_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "publication_id", "place_id"], name: "unique_records", unique: true
    t.index ["place_id"], name: "index_publications_to_places_on_place_id"
    t.index ["publication_id"], name: "index_publications_to_places_on_publication_id"
  end

  create_table "publications_to_publications", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "publication_a_id"
    t.integer "publication_b_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "publication_a_id", "publication_b_id"], name: "unique_records", unique: true
    t.index ["publication_a_id"], name: "index_publications_to_publications_on_publication_a_id"
    t.index ["publication_b_id"], name: "index_publications_to_publications_on_publication_b_id"
  end

  create_table "publications_to_standard_terms", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "standard_term_id"
    t.integer "publication_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "publication_id", "standard_term_id"], name: "unique_records", unique: true
    t.index ["publication_id"], name: "index_publications_to_standard_terms_on_publication_id"
    t.index ["standard_term_id"], name: "index_publications_to_standard_terms_on_standard_term_id"
  end

  create_table "roles", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "sources", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "source_id"
    t.integer "record_type", limit: 1, default: 0
    t.string "std_title", limit: 512
    t.string "std_title_d", limit: 512
    t.string "composer"
    t.string "composer_d"
    t.string "title", limit: 256
    t.string "title_d", limit: 256
    t.string "shelf_mark"
    t.string "language", limit: 16
    t.integer "date_from"
    t.integer "date_to"
    t.string "lib_siglum", limit: 32, collation: "utf8mb4_0900_as_cs"
    t.text "marc_source", size: :medium
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.integer "wf_owner", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "lock_version", default: 0, null: false
    t.index ["created_at"], name: "index_sources_on_created_at"
    t.index ["lib_siglum"], name: "index_sources_on_lib_siglum"
    t.index ["record_type"], name: "index_sources_on_record_type"
    t.index ["source_id"], name: "index_sources_on_source_id"
    t.index ["std_title"], name: "index_sources_on_std_title", length: 255
    t.index ["std_title_d"], name: "index_sources_on_std_title_d", length: 255
    t.index ["updated_at"], name: "index_sources_on_updated_at"
    t.index ["wf_stage"], name: "index_sources_on_wf_stage"
  end

  create_table "sources_to_institutions", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "institution_id"
    t.integer "source_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["institution_id"], name: "index_sources_to_institutions_on_institution_id"
    t.index ["marc_tag", "relator_code", "source_id", "institution_id"], name: "unique_records", unique: true
    t.index ["source_id"], name: "index_sources_to_institutions_on_source_id"
  end

  create_table "sources_to_liturgical_feasts", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "liturgical_feast_id"
    t.integer "source_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["liturgical_feast_id"], name: "index_sources_to_liturgical_feasts_on_liturgical_feast_id"
    t.index ["marc_tag", "relator_code", "liturgical_feast_id", "source_id"], name: "unique_records", unique: true
    t.index ["source_id"], name: "index_sources_to_liturgical_feasts_on_source_id"
  end

  create_table "sources_to_people", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "person_id"
    t.integer "source_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "source_id", "person_id"], name: "unique_sources_to_people", unique: true
    t.index ["person_id"], name: "index_sources_to_people_on_person_id"
    t.index ["source_id"], name: "index_sources_to_people_on_source_id"
  end

  create_table "sources_to_places", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "place_id"
    t.integer "source_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "place_id", "source_id"], name: "unique_records", unique: true
    t.index ["place_id"], name: "index_sources_to_places_on_place_id"
    t.index ["source_id"], name: "index_sources_to_places_on_source_id"
  end

  create_table "sources_to_publications", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "publication_id"
    t.integer "source_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "publication_id", "source_id"], name: "unique_records", unique: true
    t.index ["publication_id"], name: "index_sources_to_publications_on_publication_id"
    t.index ["source_id"], name: "index_sources_to_publications_on_source_id"
  end

  create_table "sources_to_sources", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "source_a_id"
    t.integer "source_b_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "source_a_id", "source_b_id"], name: "unique_sources", unique: true
    t.index ["source_a_id"], name: "index_sources_to_sources_on_source_a_id"
    t.index ["source_b_id"], name: "index_sources_to_sources_on_source_b_id"
  end

  create_table "sources_to_standard_terms", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "standard_term_id"
    t.integer "source_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "standard_term_id", "source_id"], name: "unique_records", unique: true
    t.index ["source_id"], name: "index_sources_to_standard_terms_on_source_id"
    t.index ["standard_term_id"], name: "index_sources_to_standard_terms_on_standard_term_id"
  end

  create_table "sources_to_standard_titles", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "standard_title_id"
    t.integer "source_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "standard_title_id", "source_id"], name: "unique_records", unique: true
    t.index ["source_id"], name: "index_sources_to_standard_titles_on_source_id"
    t.index ["standard_title_id"], name: "index_sources_to_standard_titles_on_standard_title_id"
  end

  create_table "sources_to_work_nodes", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.integer "source_id"
    t.integer "work_node_id"
    t.index ["source_id"], name: "index_sources_to_works_on_source_id"
    t.index ["work_node_id"], name: "index_sources_to_works_on_work_id"
  end

  create_table "sources_to_works", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "source_id"
    t.integer "work_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "source_id", "work_id"], name: "unique_records", unique: true
    t.index ["source_id"], name: "index_sources_to_works_on_source_id"
    t.index ["work_id"], name: "index_sources_to_works_on_work_id"
  end

  create_table "standard_terms", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "term", null: false
    t.text "alternate_terms"
    t.text "notes"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.integer "wf_owner", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "lock_version", default: 0, null: false
    t.text "sub_topic"
    t.string "viaf"
    t.string "gnd"
    t.index ["term"], name: "index_standard_terms_on_term"
    t.index ["wf_stage"], name: "index_standard_terms_on_wf_stage"
  end

  create_table "standard_titles", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "title", null: false
    t.string "title_d", limit: 128
    t.text "notes"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.integer "wf_owner", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "lock_version", default: 0, null: false
    t.string "typus"
    t.text "alternate_terms"
    t.text "sub_topic"
    t.string "viaf"
    t.string "gnd"
    t.boolean "latin"
    t.index ["title"], name: "index_standard_titles_on_title"
    t.index ["wf_stage"], name: "index_standard_titles_on_wf_stage"
  end

  create_table "users", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "preference_wf_stage", default: 1
    t.text "notifications"
    t.integer "notification_type"
    t.string "username"
    t.string "notification_email"
    t.boolean "disabled", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "users_roles", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
  end

  create_table "users_workgroups", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id"
    t.integer "workgroup_id"
    t.index ["user_id"], name: "index_workgroups_users_on_user_id"
    t.index ["workgroup_id"], name: "index_workgroups_users_on_workgroup_id"
  end

  create_table "versions", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", size: :long
    t.datetime "created_at", precision: nil
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "work_incipits", id: :integer, charset: "utf8mb3", force: :cascade do |t|
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
    t.integer "wf_owner", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "work_nodes", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "person_id"
    t.string "title"
    t.string "form"
    t.text "notes"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.integer "wf_owner", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "marc_source"
    t.integer "lock_version", default: 0, null: false
    t.index ["title"], name: "index_works_on_title"
    t.index ["wf_stage"], name: "index_works_on_wf_stage"
  end

  create_table "work_nodes_to_institutions", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.integer "work_node_id"
    t.integer "institution_id"
    t.index ["institution_id"], name: "index_works_to_institutions_on_institution_id"
    t.index ["work_node_id"], name: "index_works_to_institutions_on_work_id"
  end

  create_table "work_nodes_to_liturgical_feasts", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.integer "work_node_id"
    t.integer "liturgical_feast_id"
    t.index ["liturgical_feast_id"], name: "index_works_to_liturgical_feasts_on_liturgical_feast_id"
    t.index ["work_node_id"], name: "index_works_to_liturgical_feasts_on_work_id"
  end

  create_table "work_nodes_to_people", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.integer "work_node_id"
    t.integer "person_id"
    t.index ["person_id"], name: "index_works_to_people_on_person_id"
    t.index ["work_node_id"], name: "index_works_to_people_on_work_id"
  end

  create_table "work_nodes_to_publications", charset: "utf8mb3", force: :cascade do |t|
    t.integer "work_node_id"
    t.integer "publication_id"
    t.index ["publication_id"], name: "index_works_to_publications_on_publication_id"
    t.index ["work_node_id"], name: "index_works_to_publications_on_work_id"
  end

  create_table "work_nodes_to_standard_terms", charset: "utf8mb3", force: :cascade do |t|
    t.integer "work_node_id"
    t.integer "standard_term_id"
    t.index ["standard_term_id"], name: "index_works_to_standard_terms_on_standard_term_id"
    t.index ["work_node_id"], name: "index_works_to_standard_terms_on_work_id"
  end

  create_table "work_nodes_to_standard_titles", charset: "utf8mb3", force: :cascade do |t|
    t.integer "work_node_id"
    t.integer "standard_title_id"
    t.index ["standard_title_id"], name: "index_works_to_standard_titles_on_standard_title_id"
    t.index ["work_node_id"], name: "index_works_to_standard_titles_on_work_id"
  end

  create_table "workgroups", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "libpatterns"
    t.string "email"
    t.index ["email"], name: "index_workgroups_on_email"
  end

  create_table "works", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "person_id"
    t.string "title"
    t.string "opus"
    t.string "catalogue"
    t.integer "wf_audit", default: 0
    t.integer "wf_stage", default: 0
    t.integer "wf_owner", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "marc_source", size: :medium
    t.integer "lock_version", default: 0, null: false
    t.integer "link_status"
    t.index ["catalogue"], name: "index_works_on_catalogue"
    t.index ["created_at"], name: "index_works_on_created_at"
    t.index ["opus"], name: "index_works_on_opus"
    t.index ["person_id"], name: "index_works_on_person_id"
    t.index ["title"], name: "index_works_on_title"
    t.index ["updated_at"], name: "index_works_on_updated_at"
    t.index ["wf_stage"], name: "index_works_on_wf_stage"
  end

  create_table "works_to_institutions", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "work_id"
    t.integer "institution_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["institution_id"], name: "index_works_to_institutions_on_institution_id"
    t.index ["marc_tag", "relator_code", "work_id", "institution_id"], name: "unique_records", unique: true
    t.index ["work_id"], name: "index_works_to_institutions_on_work_id"
  end

  create_table "works_to_liturgical_feasts", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "work_id"
    t.integer "liturgical_feast_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["liturgical_feast_id"], name: "index_works_to_liturgical_feasts_on_liturgical_feast_id"
    t.index ["marc_tag", "relator_code", "work_id", "liturgical_feast_id"], name: "unique_records", unique: true
    t.index ["work_id"], name: "index_works_to_liturgical_feasts_on_work_id"
  end

  create_table "works_to_people", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "work_id"
    t.integer "person_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "work_id", "person_id"], name: "unique_records", unique: true
    t.index ["person_id"], name: "index_works_to_people_on_person_id"
    t.index ["work_id"], name: "index_works_to_people_on_work_id"
  end

  create_table "works_to_places", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "work_id"
    t.integer "place_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "work_id", "place_id"], name: "unique_records", unique: true
    t.index ["place_id"], name: "index_works_to_places_on_place_id"
    t.index ["work_id"], name: "index_works_to_places_on_work_id"
  end

  create_table "works_to_publications", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "work_id"
    t.integer "publication_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "work_id", "publication_id"], name: "unique_records", unique: true
    t.index ["publication_id"], name: "index_works_to_publications_on_publication_id"
    t.index ["work_id"], name: "index_works_to_publications_on_work_id"
  end

  create_table "works_to_standard_terms", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "work_id"
    t.integer "standard_term_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "work_id", "standard_term_id"], name: "unique_records", unique: true
    t.index ["standard_term_id"], name: "index_works_to_standard_terms_on_standard_term_id"
    t.index ["work_id"], name: "index_works_to_standard_terms_on_work_id"
  end

  create_table "works_to_standard_titles", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "work_id"
    t.integer "standard_title_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "work_id", "standard_title_id"], name: "unique_records", unique: true
    t.index ["standard_title_id"], name: "index_works_to_standard_titles_on_standard_title_id"
    t.index ["work_id"], name: "index_works_to_standard_titles_on_work_id"
  end

  create_table "works_to_works", id: { type: :bigint, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "work_a_id"
    t.integer "work_b_id"
    t.string "marc_tag"
    t.string "relator_code"
    t.index ["marc_tag", "relator_code", "work_a_id", "work_b_id"], name: "unique_records", unique: true
    t.index ["work_a_id"], name: "index_works_to_works_on_work_a_id"
    t.index ["work_b_id"], name: "index_works_to_works_on_work_b_id"
  end

end

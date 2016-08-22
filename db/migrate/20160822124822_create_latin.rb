class CreateLatin < ActiveRecord::Migration
  def change
    create_table :latins do |t|
      t.string :name
      t.text :alternate_terms
      t.text :notes
      t.text :sub_topic
      t.text :topic
      t.string :viag
      t.string :gnd
      t.integer  "wf_audit",        limit: 4,     default: 0
      t.integer  "wf_stage",        limit: 4,     default: 0
      t.string   "wf_notes",        limit: 255
      t.integer  "wf_owner",        limit: 4,     default: 0
      t.integer  "wf_version",      limit: 4,     default: 0
      t.integer  "src_count",       limit: 4,     default: 0
      t.integer  "lock_version",    limit: 4,     default: 0, null: false
      t.timestamps null: false
    end
    create_table "sources_to_latin", id: false, force: :cascade do |t|
      t.integer "latin_id",  limit: 4
      t.integer "source_id", limit: 4
    end

    add_index "sources_to_latin", ["latin_id"], name: "index_sources_to_latins_on_latin_id", using: :btree
    add_index "sources_to_latin", ["source_id"], name: "index_sources_to_latins_on_source_id", using: :btree
  end
end

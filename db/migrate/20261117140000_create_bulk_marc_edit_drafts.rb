class CreateBulkMarcEditDrafts < ActiveRecord::Migration[7.2]
  def change
    create_table :bulk_marc_edit_drafts do |t|
      t.bigint :folder_id, null: false
      t.bigint :requesting_user_id, null: false
      t.text :operations, null: false
      t.text :sample_snapshot, null: false
      t.string :membership_digest, null: false
      t.string :configuration_digest, null: false
      t.integer :sample_size, null: false, default: 10
      t.integer :target_count, null: false
      t.datetime :expires_at, null: false
      t.datetime :confirmed_at
      t.datetime :started_at
      t.timestamps
      t.index [:folder_id, :requesting_user_id]
      t.index :expires_at
    end
  end
end

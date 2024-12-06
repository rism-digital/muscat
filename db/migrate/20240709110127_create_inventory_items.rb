class CreateInventoryItems < ActiveRecord::Migration[7.1]
  def change
    create_table :inventory_items do |t|
      t.integer :source_id
      t.string :title
      t.string :composer
      t.text :marc_source
      t.integer :lock_version
      t.integer :wf_audit
      t.integer :wf_owner
      t.integer :wf_stage

      t.timestamps
    end
  end
end

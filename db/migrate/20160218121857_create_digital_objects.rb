class CreateDigitalObjects < ActiveRecord::Migration[4.2]
  def self.up
    create_table :digital_objects do |t|
      t.belongs_to :source, index: true
      t.string :description
      t.integer  "wf_audit",     default: 0
      t.integer  "wf_stage",     default: 0
      t.string   "wf_notes"
      t.integer  "wf_owner",     default: 0
      t.integer  "wf_version",   default: 0
      t.integer  "lock_version",             default: 0, null: false
    end
  end
  
  def self.down
    drop_table :digital_objects
  end
  
end

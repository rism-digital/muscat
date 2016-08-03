class DigitalObjectLink < ActiveRecord::Migration
  def change
    create_table :digital_object_links do |t|
      t.integer :digital_object_id
      t.references :object_link, polymorphic: true
      t.integer :wf_owner
      t.timestamps
    end
  end
end

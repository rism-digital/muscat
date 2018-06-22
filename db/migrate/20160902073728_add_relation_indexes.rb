class AddRelationIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index :folder_items, :folder_id
		add_index :folder_items, :item_id
		
		add_index :digital_object_links, :digital_object_id
		add_index :digital_object_links, :object_link_id
		add_index :digital_objects, :wf_stage
		
		add_index :folders, :folder_type
		add_index :folders, :wf_owner
  end
end
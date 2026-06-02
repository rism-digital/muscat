class CreateInventoryItemToWorkNode < ActiveRecord::Migration[7.2]
  def change
    create_table :inventory_items_to_work_nodes do |t|
      t.integer :inventory_item_id
      t.integer :work_node_id
      t.string :marc_tag
      t.string :relator_code
    end
  end
end

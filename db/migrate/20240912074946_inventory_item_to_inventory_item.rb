class InventoryItemToInventoryItem < ActiveRecord::Migration[7.1]
  def change
    create_table :inventory_items_to_inventory_items do |t|
      t.integer :inventory_item_a_id
      t.integer :inventory_item_b_id
      t.string :marc_tag
      t.string :relator_code
    end
  end
end

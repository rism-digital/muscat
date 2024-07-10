class CreateInventoryItemToSource < ActiveRecord::Migration[7.1]
  def change
    create_table :inventory_items_to_sources do |t|
      t.integer :inventory_item_id
      t.integer :source_id
      t.string :marc_tag
      t.string :relator_code

      t.timestamps
    end
  end
end

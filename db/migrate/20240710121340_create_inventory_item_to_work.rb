class CreateInventoryItemToWork < ActiveRecord::Migration[7.1]
  def change
    create_table :inventory_items_to_works do |t|
      t.integer :inventory_item_id
      t.integer :work_id
      t.string :marc_tag
      t.string :relator_code
    end
  end
end

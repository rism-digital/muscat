class CreateInventoryItemToStandardTitle < ActiveRecord::Migration[7.1]
  def change
    create_table :inventory_items_to_standard_titles do |t|
      t.integer :inventory_item_id
      t.integer :standard_title_id
      t.string :marc_tag
      t.string :relator_code
      t.timestamps
    end
  end
end

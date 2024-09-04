class CreateInventoryItemToPublication < ActiveRecord::Migration[7.1]
  def change
    create_table :inventory_items_to_publications do |t|
      t.integer :inventory_item_id
      t.integer :publication_id
      t.string :marc_tag
      t.string :relator_code
    end
  end
end

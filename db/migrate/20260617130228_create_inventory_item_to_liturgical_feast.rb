class CreateInventoryItemToLiturgicalFeast < ActiveRecord::Migration[7.2]
  def change
    create_table :inventory_items_to_liturgical_feasts do |t|
      t.integer :inventory_item_id
      t.integer :liturgical_feast_id
      t.string :marc_tag
      t.string :relator_code
    end
  end
end

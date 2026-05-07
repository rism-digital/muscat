class AddIndexesToInventoryItems < ActiveRecord::Migration[7.1]
  def change
    add_index :inventory_items,
              :source_id,
              name: :index_inventory_items_on_source_id

    add_index :inventory_items,
              [:source_id, :source_order, :id],
              name: :index_inventory_items_on_source_id_source_order_id

    add_index :inventory_items_to_sources,
              [:inventory_item_id, :marc_tag],
              name: :index_inventory_items_to_sources_on_inventory_item_id_marc_tag
  end
end


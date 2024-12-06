class InventoryItemRelation < ApplicationRecord
    self.table_name = "inventory_items_to_inventory_items"
    belongs_to :inventory_item_a, class_name: "InventoryItem"
    belongs_to :inventory_item_b, class_name: "InventoryItem"
end

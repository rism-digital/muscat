class InventoryItemSourceRelation < ApplicationRecord
    self.table_name = "inventory_items_to_sources"
    belongs_to :inventory_item
    belongs_to :source
end

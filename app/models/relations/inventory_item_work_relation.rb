class InventoryItemWorkRelation < ApplicationRecord
    self.table_name = "inventory_items_to_works"
    belongs_to :inventory_item
    belongs_to :work
end

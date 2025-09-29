class InventoryItemHoldingRelation < ApplicationRecord
    self.table_name = "inventory_items_to_holdings"
    belongs_to :inventory_item
    belongs_to :holding
end

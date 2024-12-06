class InventoryItemStandardTermRelation < ApplicationRecord
    self.table_name = "inventory_items_to_standard_terms"
    belongs_to :inventory_item
    belongs_to :standard_term
end

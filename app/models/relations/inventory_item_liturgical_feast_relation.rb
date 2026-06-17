class InventoryItemLiturgicalFeastRelation < ApplicationRecord
    self.table_name = "inventory_items_to_liturgical_feasts"
    belongs_to :inventory_item
    belongs_to :liturgical_feast
end
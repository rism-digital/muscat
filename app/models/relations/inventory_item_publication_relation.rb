class InventoryItemPublicationRelation < ApplicationRecord
    self.table_name = "inventory_items_to_publications"
    belongs_to :inventory_item
    belongs_to :publication
end

class InventoryItemStandardTitleRelation < ApplicationRecord
    self.table_name = "inventory_items_to_standard_titles"
    belongs_to :inventory_item
    belongs_to :standard_title
end

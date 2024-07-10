class InventoryItemPersonRelation < ApplicationRecord
    self.table_name = "inventory_items_to_people"
    belongs_to :inventory_item
    belongs_to :person
end

class InventoryItemInstitutionRelation < ApplicationRecord
    self.table_name = "inventory_items_to_institutions"
    belongs_to :inventory_item
    belongs_to :institution
end

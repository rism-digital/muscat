class InventoryItemWorkNodeRelation < ApplicationRecord
    self.table_name = "inventory_items_to_work_nodes"
    belongs_to :inventory_item
    belongs_to :work_node
end

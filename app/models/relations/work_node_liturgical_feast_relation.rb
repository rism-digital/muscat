class WorkNodeLiturgicalFeastRelation < ApplicationRecord
    self.table_name = "work_nodes_to_liturgical_feasts"
    belongs_to :work_node
    belongs_to :liturgical_feast
end


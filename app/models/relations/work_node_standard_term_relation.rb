class WorkNodeStandardTermRelation < ApplicationRecord
    self.table_name = "work_nodes_to_standard_terms"
    belongs_to :work_node
    belongs_to :standard_term
end


class WorkNodeInstitutionRelation < ApplicationRecord
    self.table_name = "work_nodes_to_institutions"
    belongs_to :work_node
    belongs_to :institution
end


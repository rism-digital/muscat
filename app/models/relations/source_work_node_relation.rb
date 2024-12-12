class SourceWorkNodeRelation < ApplicationRecord
    self.table_name = "sources_to_work_nodes"
    belongs_to :source
    belongs_to :work_node
end

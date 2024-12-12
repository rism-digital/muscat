class WorkNodePublicationRelation < ApplicationRecord
    self.table_name = "work_nodes_to_publications"
    belongs_to :work_node
    belongs_to :publication
end


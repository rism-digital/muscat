class WorkNodeStandardTitleRelation < ApplicationRecord
    self.table_name = "work_nodes_to_standard_titles"
    belongs_to :work_node
    belongs_to :standard_title
end


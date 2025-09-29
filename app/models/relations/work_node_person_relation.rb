class WorkNodePersonRelation < ApplicationRecord
    self.table_name = "work_nodes_to_people"
    belongs_to :work_node
    belongs_to :person
end


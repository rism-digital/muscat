class WorkRelation < ApplicationRecord
    self.table_name = "works_to_works"
    belongs_to :work_a, class_name: "Work"
    belongs_to :work_b, class_name: "Work"
end

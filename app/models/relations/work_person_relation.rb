class WorkPersonRelation < ApplicationRecord
    self.table_name = "works_to_people"
    belongs_to :work
    belongs_to :person
end


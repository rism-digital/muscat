class PersonRelation < ApplicationRecord
    self.table_name = "people_to_people"
    belongs_to :person_a, class_name: "Person"
    belongs_to :person_b, class_name: "Person"
end

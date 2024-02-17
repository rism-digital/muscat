class PersonPlaceRelation < ApplicationRecord
    self.table_name = "people_to_places"
    belongs_to :person
    belongs_to :place
end

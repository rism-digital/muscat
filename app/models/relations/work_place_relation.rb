class WorkPlaceRelation < ApplicationRecord
    self.table_name = "works_to_places"
    belongs_to :work
    belongs_to :place
end


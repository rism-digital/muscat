class InstitutionPlaceRelation < ApplicationRecord
    self.table_name = "institutions_to_places"
    belongs_to :institution
    belongs_to :place
end

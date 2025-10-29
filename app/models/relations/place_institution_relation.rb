class PlaceInstitutionRelation < ApplicationRecord
    self.table_name = "places_to_institutions"
    belongs_to :place
    belongs_to :institution
end

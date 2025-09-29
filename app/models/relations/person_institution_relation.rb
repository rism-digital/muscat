class PersonInstitutionRelation < ApplicationRecord
    self.table_name = "people_to_institutions"
    belongs_to :person
    belongs_to :institution
end

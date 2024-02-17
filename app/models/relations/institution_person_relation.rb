class InstitutionPersonRelation < ApplicationRecord
    self.table_name = "institutions_to_people"
    belongs_to :institution
    belongs_to :person
end

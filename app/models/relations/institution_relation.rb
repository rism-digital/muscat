class InstitutionRelation < ApplicationRecord
    self.table_name = "institutions_to_institutions"
    belongs_to :institution_a, class_name: "Institution"
    belongs_to :institution_b, class_name: "Institution"
end

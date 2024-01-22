class WorkInstitutionRelation < ApplicationRecord
    self.table_name = "works_to_institutions"
    belongs_to :work
    belongs_to :institution
end


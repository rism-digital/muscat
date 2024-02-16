class HoldingInstitutionRelation < ApplicationRecord
    self.table_name = "holdings_to_institutions"
    belongs_to :holding
    belongs_to :institution
end

class SourceInstitutionRelation < ApplicationRecord
    self.table_name = "sources_to_institutions"
    belongs_to :source
    belongs_to :institution
end

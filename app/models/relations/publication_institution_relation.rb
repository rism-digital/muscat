class PublicationInstitutionRelation < ApplicationRecord
    self.table_name = "publications_to_institutions"
    belongs_to :publication
    belongs_to :institution
end

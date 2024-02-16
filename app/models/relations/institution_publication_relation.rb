class InstitutionPublicationRelation < ApplicationRecord
    self.table_name = "institutions_to_publications"
    belongs_to :institution
    belongs_to :publication
end

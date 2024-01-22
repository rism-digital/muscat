class PublicationStandardTermRelation < ApplicationRecord
    self.table_name = "publications_to_standard_terms"
    belongs_to :publication
    belongs_to :standard_term
end

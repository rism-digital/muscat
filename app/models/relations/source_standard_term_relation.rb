class SourceStandardTermRelation < ApplicationRecord
    self.table_name = "sources_to_standard_terms"
    belongs_to :source
    belongs_to :standard_term
end

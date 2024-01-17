class SourcePublicationRelation < ApplicationRecord
    self.table_name = "sources_to_publications"
    belongs_to :source
    belongs_to :publication
end

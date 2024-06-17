class SourcePlaceRelation < ApplicationRecord
    self.table_name = "sources_to_places"
    belongs_to :source
    belongs_to :place
end

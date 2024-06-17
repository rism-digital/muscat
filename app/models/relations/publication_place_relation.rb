class PublicationPlaceRelation < ApplicationRecord
    self.table_name = "publications_to_places"
    belongs_to :publication
    belongs_to :place
end

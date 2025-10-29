class PlacePublicationRelation < ApplicationRecord
    self.table_name = "places_to_publications"
    belongs_to :place
    belongs_to :publication
end

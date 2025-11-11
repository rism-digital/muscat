class PlaceRelation < ApplicationRecord
    self.table_name = "places_to_places"
    belongs_to :place_a, class_name: "Place"
    belongs_to :place_b, class_name: "Place"
end

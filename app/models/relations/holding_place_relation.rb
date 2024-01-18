class HoldingPlaceRelation < ApplicationRecord
    self.table_name = "holdings_to_places"
    belongs_to :holding
    belongs_to :place
end

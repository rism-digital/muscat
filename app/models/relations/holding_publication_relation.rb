class HoldingPublicationRelation < ApplicationRecord
    self.table_name = "holdings_to_publications"
    belongs_to :holding
    belongs_to :publication
end

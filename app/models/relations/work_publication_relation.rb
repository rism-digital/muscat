class WorkPublicationRelation < ApplicationRecord
    self.table_name = "works_to_publications"
    belongs_to :work
    belongs_to :publication
end


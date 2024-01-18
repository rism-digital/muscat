class HoldingPersonRelation < ApplicationRecord
    self.table_name = "holdings_to_people"
    belongs_to :holding
    belongs_to :person
end

class SourcePersonRelation < ApplicationRecord
    self.table_name = "sources_to_people"
    belongs_to :source
    belongs_to :person
end

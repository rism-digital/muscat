class PersonPublicationRelation < ApplicationRecord
    self.table_name = "people_to_publications"
    belongs_to :person
    belongs_to :publication
end

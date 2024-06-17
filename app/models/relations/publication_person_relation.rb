class PublicationPersonRelation < ApplicationRecord
    self.table_name = "publications_to_people"
    belongs_to :publication
    belongs_to :person
end

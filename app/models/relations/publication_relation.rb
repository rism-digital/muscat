class PublicationRelation < ApplicationRecord
    self.table_name = "publications_to_publications"
    belongs_to :publication_a, class_name: "Publication"
    belongs_to :publication_b, class_name: "Publication"
end

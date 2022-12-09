class SourceRelation < ApplicationRecord
    self.table_name = "sources_to_sources"
    belongs_to :source_a, class_name: "Source"
    belongs_to :source_b, class_name: "Source"
end

class SourceWorkRelation < ApplicationRecord
    self.table_name = "sources_to_works"
    belongs_to :source
    belongs_to :work
end

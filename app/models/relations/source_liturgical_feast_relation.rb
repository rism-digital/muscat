class SourceLiturgicalFeastRelation < ApplicationRecord
    self.table_name = "sources_to_liturgical_feasts"
    belongs_to :source
    belongs_to :liturgical_feast
end

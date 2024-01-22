class WorkLiturgicalFeastRelation < ApplicationRecord
    self.table_name = "works_to_liturgical_feasts"
    belongs_to :work
    belongs_to :liturgical_feast
end


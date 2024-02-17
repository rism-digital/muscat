class WorkStandardTermRelation < ApplicationRecord
    self.table_name = "works_to_standard_terms"
    belongs_to :work
    belongs_to :standard_term
end


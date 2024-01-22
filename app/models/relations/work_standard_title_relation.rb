class WorkStandardTitleRelation < ApplicationRecord
    self.table_name = "works_to_standard_titles"
    belongs_to :work
    belongs_to :standard_title
end


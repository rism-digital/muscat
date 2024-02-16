class SourceStandardTitleRelation < ApplicationRecord
    self.table_name = "sources_to_standard_titles"
    belongs_to :source
    belongs_to :standard_title
end

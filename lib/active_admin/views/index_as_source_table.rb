require 'active_admin/views/index_as_table'

module ActiveAdmin
  module Views
    class IndexAsSourceTable < IndexAsTable
      def table_for(*args, &block)
        insert_tag SourceTableFor, *args, &block
      end

      class SourceTableFor < IndexAsTable::IndexTableFor
        protected

        def build_table_cell(column, resource)
          return super unless resource.is_a?(SourceIndex::Tombstone)

          # One cell spans the entire row. Do not evaluate normal column
          # blocks: missing records cannot be selected, opened or edited.
          if @columns.one?
            td "Source #{resource.id}: this record exists in SOLR but not in the database.",
              colspan: 1, class: 'solr_tombstone'
          else
            current_arbre_element.children.first.set_attribute(:colspan, @columns.size)
          end
        end
      end
    end
  end
end

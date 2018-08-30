# lib/active_admin/views/index_as_grouped_table.rb
require 'active_admin/views/index_as_table'

module ActiveAdmin
  module Views
    
     # # Index as a Table
     #
     # Custom class for displaying comments gouped by resource_id/type
     #
     # Also see ./app/admin/comments.rb for controller index. 
     #
     # Each comment group performs a query for retrieving the comment list
    
    class IndexAsComment < ActiveAdmin::Component

      def build(page_presenter, collection)
        @page_presenter = page_presenter
        @collection = collection.to_a
        build_div
      end

      def self.index_name
        "table"
      end

      protected

      def build_div
        @collection.each do |item|
          div class: 'panel' do
            build_item(item)
          end
        end
      end

      def build_item(item)
        h3 auto_link(item.resource)
        div class: 'panel_contents', for: item do
          instance_exec(item, &@page_presenter.block)
        end
      end

    end
    
  end
end
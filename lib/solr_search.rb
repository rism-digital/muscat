module Muscat
  module Adapters
    module ActiveRecord
      module Base
  
        MAX_PER_PAGE = 30
  
        def search_as_ransack(params)
          fields, order, page = unpack_params(params)
          search_with_solr(fields, order, page)
        end
      
        def near_items_as_ransack(params, item)
          prev_id = nil
          next_id = nil
          fields, order, page = unpack_params(params)
          results = search_with_solr(fields, order, page)
          
          position = results.index(item)
          
          return nil, nil if position == nil
          
          # Find the previous and next items
          # It could be condensed in one
          # but it is easyer to read like this
          
          # Get the prev item in the searc
          if position == 0
            if !results.first_page?
              results_prev_page = search_with_solr(fields, order, results.previous_page)
              prev_id = results_prev_page.last
            end
          else
            prev_id = results[position - 1]
          end
          
          # get the next item in the search
          if position == MAX_PER_PAGE - 1
            if !results.last_page?
              results_next_page = search_with_solr(fields, order, results.next_page)
              next_id = results_next_page.first
            end
          else
            next_id = results[position + 1]
          end
          
          return prev_id, next_id
          
        end
            
      private
        
        def search_with_solr(fields = [], order = {}, page = 1)
        
          solr_results = self.solr_search do
            if !order.empty?
              order_by order[:field], order[:order]
            end
            
            fields.each do |f|
              if f[:fields].empty?
                fulltext f[:value]
              else
                fulltext f[:value], :fields => f[:fields]
              end
            end

            paginate :page => page, :per_page => MAX_PER_PAGE
          end
          return solr_results.results

        end # search_with_solr
        
        def unpack_params(params)
          fields = []
          order = {}
          page = params.has_key?(:page) ? params[:page] : 1
          
          if params.has_key?(:order)
            order = params[:order].include?("_asc") ? "asc" : "desc"
            field = params[:order].gsub("_#{order}", "")

            order = {:field => field.underscore.to_sym, :order => order.to_sym}      
          end
          
          options = params[:q]
          if options
            options.keys.each do |k|
              # to have it dynamic:
              #:fields => [k.to_sym]
              f = []
              if k == :title_or_std_title_contains
                f = [:title, :std_title]
              elsif k == :composer_contains
                f = [:composer]
              elsif k == :lib_siglum_contains
                f = [:lib_siglum]
              end
            
              fields << {:fields => f, :value => options[k]}
            end
          else
            # if no field is specified
            # return all elements
            fields <<{:fields => [], :value => "*"}
            # If ordering is not given
            # order by id, default in sunspot is
            # by :score
            if order.empty?
              order = {:field => :id, :order => :asc}
            end
          end
          
          return fields, order, page
        end
        
      end
    end
  end
end

ActiveRecord::Base.extend Muscat::Adapters::ActiveRecord::Base
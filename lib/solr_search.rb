module Muscat
  module Adapters
    module ActiveRecord
      module Base
  
        MAX_PER_PAGE = 30
  
        def search_as_ransack(params)
          return nil if !params.has_key?(:q)
          fields, order, page = unpack_params(params)
          search_with_solr(fields, order, page)
        end
      
        def previous_as_ransack(params, item)
          results = search_with_solr_or_activerecord(params)
          
          position = results.index(item)
          
          return nil if position == 0 && results.first_page?
          
          if position == 0
            results = search_with_solr_or_activerecord(params, results.previous_page)
            item = results.last
          else
            item = results[position - 1]
          end
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
          
          options = params[:q]
          return fields, order, page if !options
          
          if params.has_key?(:order)
            order = params[:order].include?("_asc") ? "asc" : "desc"
            field = params[:order].gsub("_#{order}", "")

            order = {:field => field.underscore.to_sym, :order => order.to_sym}      
          end
          
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
          
          return fields, order, page
        end
        
        def search_with_solr_or_activerecord(params, page = 0)
          results = nil
          ap params
          purged_params = params.except(:id)
          if !params.has_key?(:q) && 1==0# No query.
            if page != 0
              results = self.search.result.page(page).per(MAX_PER_PAGE)
            else
              param_page = params.has_key?(:page) ? params[:page] : 1
              results = self.search.result.page(param_page).per(MAX_PER_PAGE)
            end
          else
            fields, order, param_page = unpack_params(params)
            param_page = page == 0 ? param_page : page
            results = search_with_solr(fields, order, param_page)
          end
          
          return results
        end
        
      end
    end
  end
end

ActiveRecord::Base.extend Muscat::Adapters::ActiveRecord::Base
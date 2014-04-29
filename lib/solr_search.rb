module Muscat
  module Adapters
    module ActiveRecord
      module Base
  
        def search_as_ransack(params)
          options = params[:q]
          return nil if !options
    
          page = params.has_key?(:page) ? params[:page] : 1

          solr_results = self.solr_search do

            if params.has_key?(:order)
              order = params[:order].include?("_asc") ? "asc" : "desc"
              field = params[:order].gsub("_#{order}", "")

              order_by field.underscore.to_sym, order.to_sym      
            end

            options.keys.each do |k|
              # to have it dynamic:
              #:fields => [k.to_sym]
              fields = [] # by default on all fields
              if k == :title_or_std_title_contains
                fields = [:title, :std_title]
              elsif k == :composer_contains
                fields = [:composer]
              elsif k == :lib_siglum_contains
                fields = [:lib_siglum]
              end

              if fields.empty?
                fulltext options[k]
              else
                fulltext options[k], :fields => fields
              end
            end

            paginate :page => page, :per_page => 30
          end
          ap solr_results.results
          return solr_results.results

        end
        
      end
    end
  end
end

ActiveRecord::Base.extend Muscat::Adapters::ActiveRecord::Base
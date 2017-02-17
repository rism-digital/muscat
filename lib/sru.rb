# This module provides an easy and simple SRU server for muscat
# The service is accessible at 
# eg. http://[host]/sru?operation=searchRetrieve&version=1.1&query=author=bach&maximumRecords=10 
#
# Queries are combined with "+AND+"
# eg. http://[host]/sru?operation=searchRetrieve&version=1.1&query=author=bach+AND+subject=Masses&maximumRecords=10
#
# Mapping between the parameter elements and the marc-index is configured in the config/sru folder.
#
# This module uses an index config file in the config/sru-folder to match the Solr fields with the search parameter
# The impleentation follows http://www.loc.gov/standards/sru/sru-1-2.html

module Sru
  class Query
    NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
    attr_accessor :operation, :query, :maximumRecords, :model, :error_code
    
    def initialize(model, params = {})
      @model = model.singularize.camelize.constantize rescue nil
      # TODO class variable for caching
      @@index_config = YAML.load_file("config/sru/service.config.yml")['index']
      @operation=params.fetch(:operation, 'searchRetrieve')
      @query=_parse(params.fetch(:query, '*'))
      @maximumRecords=params.fetch(:maximumRecords, 10).to_i rescue 10
      @error_code = self._check
    end

    # Returns the solr query result
    def response
      require 'cql_ruby'
      if !error_code
        begin
          parser = CqlRuby::CqlParser.new
          q = parser.parse(self.query).to_solr
          if q.include?(":")
            solr_result = Sunspot.search(@model) do
              adjust_solr_params do |params|
                params[:q] = q
              end
            end
          else
            # Fulltext search
            solr_result = Sunspot.search(@model) do
              fulltext q
            end
          end
          return solr_result
        rescue
          @error_code = "Index field is not defined for this model"
        end
      else
        return error_code
      end
    end

    # Check if params is valid
    def _check
      if !self.operation || self.operation != 'searchRetrieve'
        return "PARAMETER 'searchRetreive' not given"
      end
      unless self.model
        return "Database #{model} not existent"
      end
      if query.empty?
        return "Query string is empty"
      end
      # Check if the index is in the config
      #if !(self.query.keys - @@index_config.keys).empty? && !self.query.values.include?(nil)
      #  return "Unsupported index"
      #end
      return nil
    end

    # Helper method to parse the query string into a hash
    def _parse(s)
      fields = s.split(" AND ")
      res = []
      fields.each do |field|
        unless field.include?("=")
          return "#{field}"
        end
        hash = Rack::Utils.parse_nested_query(field)
        hash.each do |k,v|
          solr = "text"
          @@index_config.each do |key, value|
            if key == k || k == key.gsub(/^\w+\./ , "")
              solr = value['solr']
              break
            end
          end
          res << "#{solr}=#{v}"
        end
      end
      return res.join(" AND ")
    end
  end
end

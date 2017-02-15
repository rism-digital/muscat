# This module provides an easy and simple SRU server for muscat
# The service is accessible at 
# eg. http://[host]/sru?operation=searchRetrieve&version=1.1&query=author=bach&maximumRecords=10 
#
# Queries are combined with "+AND+"
# eg. http://[host]/sru?operation=searchRetrieve&version=1.1&query=author=bach+AND+subject=Masses&maximumRecords=10 
#
# This module uses an index config file in the config/sru-folder to match the Solr fields with the search parameter
# The impleentation follows http://www.loc.gov/standards/sru/sru-1-2.html

module Sru
  class Query
    # TODO make this generic
    NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
    attr_accessor :operation, :query, :maximumRecords
    
    def initialize(params = {})
      # TODO class variable for caching
      @@sru_config = YAML.load_file("config/sru/sources_sru_fields.yml")
      @operation=params.fetch(:operation, 'searchRetrieve')
      @query=_parse(params.fetch(:query, '*'))
      @maximumRecords=params.fetch(:maximumRecords, 10).to_i rescue 10
    end

    # Returns the solr query result
    def response
      if self._is_valid?
        sources = Source.solr_search do
          query.each do |k,v|
            fulltext v, :fields => @@sru_config[k]
          end
          paginate :page => 1, :per_page => maximumRecords
        end
        return sources
      else
        return false
      end
    end

    # Check if params is valid
    def _is_valid?
      return false if !self.operation || self.operation != 'searchRetrieve'
      return false if query.empty?
      # Check if the index is in the config
      return false unless (query.keys - @@sru_config.keys).empty?
      return true
    end

    # Helper method to parse the query string into a hash
    def _parse(params)
      q = {}
      fields = params.split(" AND ")
      fields.each do |field|
        index, term = field.split("=")
        q[index] = term
      end
      return q
    end
  end
end

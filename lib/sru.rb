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
      @error_code = self._check if !@error_code
    end

    # Returns the solr query result
    def response
      if !error_code
        #begin
          solr_result = @model.solr_search do
            query.each do |field, value|
              if value[:type]
                if value[:type] == 'text'
                  fulltext value[:term], :fields => field
                else
                  #with(field.to_sym).greater_than_or_equal_to Time.parse(value[:term])
                  with(field).equal_to value[:term]
                end
              else
                fulltext value[:term]
              end
              # only published records are used
              with(:wf_stage).equal_to("published") if @model=="sources"
            end
            paginate :page => 1, :per_page => maximumRecords
          end
          return solr_result
        #rescue
        #  @error_code = "Index field is not defined for this model"
        #end
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
      return nil
    end

    # Helper method to parse the query string into a hash
    def _parse(s)
      fields = s.split(" AND ")
      res = {}
      # use scan as tokenizer: content.scan(/\w+|\W/)
      fulltext = 0
      fields.each do |field|
        field, term = field.split("=")
          unless term
            res[fulltext] = {:term => field, :type => nil}
            fulltext += 1
          end
          @@index_config.each do |key, value|
            if key == field || field == key.gsub(/^\w+\./ , "")
              res[value['solr']] = {:term => term, :type => value['type']}
            end
          end
        end
      # If we have missing fields in the result: 
      @error_code = "Unsupported index, see explain" if res.size != fields.size
      return res
    end
  end
end

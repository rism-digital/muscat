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
    attr_accessor :operation, :query, :maximumRecords, :model, :result, :error_code
    
    def initialize(model, params = {})
      @model = model.singularize.camelize.constantize rescue nil
      # TODO class variable for caching
      @@index_config = YAML.load_file("config/sru/service.config.yml")['index']
      @operation=params.fetch(:operation, 'searchRetrieve')
      @query=params.fetch(:query, '*')
      @maximumRecords=params.fetch(:maximumRecords, 10).to_i rescue 10
      @error_code = self._check if !@error_code
      @result = self._response
    end

    # Returns the solr query result
    def _response
      if !error_code
        begin
          q = self._to_solr(@query)
            solr_result = Sunspot.search(@model) do
              adjust_solr_params do |params|
                params[:q] = q
              end
              with(:wf_stage).equal_to("published") if @model=="sources"
              paginate :page => 1, :per_page => maximumRecords
            end
          return solr_result
        rescue
          @error_code = "Index field is not defined for this model"
        end
      else
        return nil
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

    def _to_solr(s)
      require 'cql_ruby'
      index_config = YAML.load_file("config/sru/service.config.yml")['index']
      token = CqlRuby::CqlLexer.new.tokenize(s)
      subqueries = []
      token.chunk {|e| !(e =~ /^(AND|and|OR|or|NOT|not|PROX|prox)$/) }.each {|a| subqueries << a }
      subqueries.each_with_index do |query, index|
        if query[0]
          print query[1]
          if query[1].any? {|e| e =~ /^[=<>]/}
            index_config.each do |k,v|
              if query[1][0] == k || query[1][0] == k.gsub(/^\w+\./ , "")
                if v['solr'].instance_of?(Array)
                  ary = []
                  v['solr'].each do |e|
                    ary << "#{e}_text=#{query[1][-1]}"
                  end
                  subqueries[index][1] = ["#{ary.join(" OR ")}"]
                else
                  if v['type'] == "d"
                    date = Time.parse(query[1][-1])
                    subqueries[index][1][0] = "#{v['solr']}_#{v['type']}"
                    subqueries[index][1][-1] = "#{date.strftime("%Y-%m-%d")}T23:59:59Z"
                  else
                    subqueries[index][1][0]="#{v['solr']}_#{v['type']}"
                  end
                end
                break
              #else
              #  @error_code = "Index not supported"
              end
            end
          else
            fulltext = []
            index_config['cql.any']['solr'].each do |solr_index|
              fulltext << "#{solr_index}_text=#{query[1][-1]}"
            end
            subqueries[index][1] = ["(#{fulltext.join(" OR ")})"]
          end
        end
      
      end
      cql_string = subqueries.map{|e| e[1]}.join(" ")
      solr_string = CqlRuby::CqlParser.new.parse(cql_string).to_solr
      puts "#{cql_string} => #{solr_string}"
      return solr_string
    end


  end
end

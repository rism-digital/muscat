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
    PARAMS = ["query", :query, "maximumRecords", "operation", :operation, "version", "startRecord", 
            "maximumTerms", "responsePosition", "scanClause", "controller", "action", "recordSchema", "x-action"]
    
    attr_accessor :operation, :query, :maximumRecords, :offset, :model, :result, :error_code, :schema, :scan, :version

    def initialize(model, params = {})
      @version=params.fetch(:version, '1.1')
      unless (params.keys - PARAMS).empty?
        @error_code = {:code => 8 , :message => "Unsupported parameter"}
      end
      @model = model.singularize.camelize.constantize rescue nil
      # TODO class variable for caching
      sru_config = YAML.load_file("config/sru/service.config.yml")
      @@index_config = sru_config['index']
      @operation=params.fetch(:operation, 'searchRetrieve')
      @query=params.fetch(:query, '*')
      if params[:operation] == 'scan'
        @query=params.fetch(:scanClause)
      end
      if params[:operation]=='searchRetrieve' && !params[:query]
        @error_code = {:code => 7, :message => "Mandatory parameter not supplied"}
      end
      @maximumRecords=params.fetch(:maximumRecords, 10).to_i rescue 10
      if @maximumRecords.instance_of?(Integer) && @maximumRecords > sru_config['server']['maximumRecords']
        if params['x-action']
          # To prevent backdoor download
          if @maximumRecords > 2000
            @error_code = {:code => 60, :message => "Result set not created: too many matching records (code 60): MaximumRecords is limited to 2000"}
          end
        else
          @error_code = {:code => 60, :message => "Result set not created: too many matching records (code 60): MaximumRecords is limited to #{sru_config['server']['maximumRecords']} records"}
        end
      end
      @offset = params.fetch("startRecord", 1).to_i rescue 1
      @error_code = self._check if !@error_code
      @schema = params.fetch(:recordSchema, "marc")
      if !sru_config['schemas'].include?(@schema)
        @error_code =  {:code => 67, :message => "Record not available in this schema"}
      end
      @result = self._response if !@error_code
    end

    # Returns the solr query result
    def _response
      if !error_code
        begin
          q = self._to_solr(query)
          solr_result = Sunspot.search(model) do
            adjust_solr_params do |params|
              params[:q] = q
              params[:start] = (offset - 1)
              params[:rows] = maximumRecords
            end
            with(:wf_stage).equal_to("published") if model==Source
            order_by(:id, :asc)
          end
          return solr_result
        rescue
          @error_code = {:code => 10, :message => "Query syntax error"}
        end
      else
        return nil
      end
    end

    # Check if params is valid
    def _check
      if !self.operation
        return {:code => 7, :message => "Mandatory parameter not supplied"}
      end
      if self.version != '1.1'
        return {:code => 5, :message => "unsupported version"}
      end
      if self.maximumRecords == 0
        return {:code => 6, :message => "unsupported parameter value"}
      end
      if self.offset.to_i > 999999
        return {:code => 61, :message => "first record out of range"}
      end
      unless self.model
        return {:code => 235, :message => "Database does not exist"}
      end
      if query.empty?
        return {:code => 10, :message => "Query syntax error (code 10): query is empty"}
      end
      return nil
    end

    def _to_solr(s)
      if s=="*"
        return s
      end
      require 'cql_ruby'
      index_config = YAML.load_file("config/sru/service.config.yml")['index']
      token = CqlRuby::CqlLexer.new.tokenize(s)
      subqueries = []
      token.chunk {|e| !(e =~ /^(AND|and|OR|or|NOT|not|PROX|prox)$/) }.each {|a| subqueries << a }
      index_exist = false
      subqueries.each_with_index do |query, idx|
        # TODO make this more readable :-)
        if query[0]
          index=query[1][0]
          operator=query[1][1]
          term=query[1][2]
          if operator =~ /^[=<>]/
            index_config.each do |k,v|
              if index == k || index == k.gsub(/^\w+\./ , "")
                index_exist = true
                if v['solr'].instance_of?(Array)
                  ary = []
                  v['solr'].each do |e|
                    ary << "#{e}_text=#{query[1][-1]}"
                  end
                  subqueries[idx][1] = ["(#{ary.join(" OR ")})"]
                else
                  if v['type'] == "d"
                    date = Time.parse(term)
                    subqueries[idx][1][0] = "#{v['solr']}_#{v['type']}"
                    subqueries[idx][1][-1] = "#{date.strftime("%Y-%m-%d")}T23:59:59Z"
                  else
                    subqueries[idx][1][0]="#{v['solr']}_#{v['type']}"
                  end
                end
                break
              end
            end
          else
            index_exist=true
            fulltext = []
            index_config['cql.any']['solr'].each do |solr_index|
              fulltext << "#{solr_index}_text=#{index}"
            end
            subqueries[idx][1] = ["(#{fulltext.join(" OR ")})"]
          end
        end

      end
      cql_string = subqueries.map{|e| e[1]}.join(" ")
      solr_string = CqlRuby::CqlParser.new.parse(cql_string).to_solr
      if solr_string =~ /".*\*"/
        solr_string.gsub!("\"", "")
      end
      if !index_exist
        @error_code = {:code => 16, :message => "Unsupported index"}
        return 0
      end
      #puts "#{cql_string} => #{solr_string}"
      return solr_string
    end


  end
end

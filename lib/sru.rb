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

require "cql_ruby"

module Sru
  class Query
    NAMESPACE = { 'marc' => "http://www.loc.gov/MARC21/slim" }.freeze
    MODEL_CLASSES = {
      "sources" => Source,
      "people" => Person,
      "institutions" => Institution,
      "publications" => Publication,
      "works" => WorkNode
    }.freeze
    OPERATIONS = %w[explain scan searchRetrieve].freeze
    PARAMS = %w[
      query maximumRecords operation version startRecord maximumTerms
      responsePosition scanClause recordSchema deprecatedIds
    ].freeze
    MAXIMUM_QUERY_BYTES = 4_096
    MAXIMUM_START_RECORD = 100_000
    
    attr_accessor :operation, :query, :maximumRecords, :offset, :model, :result, :error_code, :schema, :scan, :version, :deprecatedIds

    def initialize(model, params = {}, maximum_records_limit: nil)
      params = params.to_h.deep_stringify_keys
      sru_config = YAML.safe_load_file(Rails.root.join("config/sru/service.config.yml"), aliases: false)
      maximum_records_limit ||= sru_config.dig("server", "maximumRecords")

      @error_code = { code: 8, message: "Unsupported parameter" } unless (params.keys - PARAMS).empty?
      @error_code ||= { code: 6, message: "Unsupported parameter value" } unless scalar_parameters?(params)
      @error_code ||= { code: 6, message: "Unsupported parameter value" } unless optional_integer_parameters_valid?(params)

      @model = MODEL_CLASSES[model.to_s]
      @version = params.fetch("version", "1.1")
      @operation = params.fetch("operation", "explain")
      @query = query_for(params)
      @maximumRecords = positive_integer(params.fetch("maximumRecords", 10))
      @offset = positive_integer(params.fetch("startRecord", 1))
      @schema = params.fetch("recordSchema", "marc")
      @deprecatedIds = params.fetch("deprecatedIds", true)

      @error_code ||= _check(maximum_records_limit)
      unless sru_config["schemas"].include?(@schema)
        @error_code ||= { code: 67, message: "Record not available in this schema" }
      end
      @result = _response unless @error_code || operation == "explain"
    end

    # Returns the solr query result
    def _response
      q = _to_solr(query)
      return if error_code

      Sunspot.search(model) do
        adjust_solr_params do |params|
          params[:q] = q
          params[:start] = (offset - 1)
          params[:rows] = maximumRecords
        end
        with(:wf_stage).equal_to("published") if model == Source
        order_by(:id, :asc)
      end
    rescue CqlException
      @error_code = { code: 10, message: "Query syntax error" }
      nil
    rescue StandardError => error
      Rails.logger.error("SRU query failed error=#{error.class}")
      @error_code = { code: 1, message: "System temporarily unavailable" }
      nil
    end

    # Check if params is valid
    def _check(maximum_records_limit)
      return { code: 6, message: "Unsupported parameter value" } unless OPERATIONS.include?(operation)
      return { code: 5, message: "Unsupported version" } unless version == "1.1"
      unless maximumRecords
        return { code: 6, message: "maximumRecords must be a positive integer" }
      end
      if maximumRecords > maximum_records_limit
        return {
          code: 60,
          message: "Result set not created: MaximumRecords is limited to #{maximum_records_limit} records"
        }
      end
      return { code: 6, message: "startRecord must be a positive integer" } unless offset
      if offset > MAXIMUM_START_RECORD
        return { code: 61, message: "First record out of range" }
      end
      return { code: 235, message: "Database does not exist" } unless model
      if operation == "searchRetrieve" && query.nil?
        return { code: 7, message: "Mandatory parameter not supplied" }
      end
      if operation == "scan" && query.nil?
        return { code: 7, message: "Mandatory parameter not supplied" }
      end
      return { code: 6, message: "Unsupported parameter value" } unless query.is_a?(String)
      if query.blank?
        return { code: 10, message: "Query syntax error (code 10): query is empty" }
      end
      if query.to_s.bytesize > MAXIMUM_QUERY_BYTES
        return { code: 10, message: "Query syntax error: query is too long" }
      end

      nil
    end

    def query_for(params)
      case params["operation"]
      when "scan"
        params["scanClause"] || params["query"]
      when "searchRetrieve"
        params["query"]
      else
        params.fetch("query", "*")
      end
    end

    def positive_integer(value)
      return value if value.is_a?(Integer) && value.positive?
      return unless value.is_a?(String) && value.match?(/\A[1-9]\d*\z/)

      Integer(value, 10)
    rescue ArgumentError
      nil
    end

    def scalar_parameters?(params)
      params.values.all? do |value|
        value.nil? || value.is_a?(String) || value.is_a?(Numeric) || value == true || value == false
      end
    end

    def optional_integer_parameters_valid?(params)
      %w[maximumTerms responsePosition].all? do |name|
        !params.key?(name) || positive_integer(params[name])
      end
    end

    def _to_solr(s)
      if s=="*"
        return s
      end
      index_config = YAML.safe_load_file(
        Rails.root.join("config/sru/service.config.yml"),
        aliases: false
      )["index"]
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

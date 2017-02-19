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
      @query=params.fetch(:query, '*')
      @maximumRecords=params.fetch(:maximumRecords, 10).to_i rescue 10
      @error_code = self._check if !@error_code
    end

    # Returns the solr query result
    def response
      if !error_code
        #begin
        q = self.to_solr(@query)
        #if q.include?(":")
          solr_result = Sunspot.search(@model) do
            adjust_solr_params do |params|
              params[:q] = q
            end
            with(:wf_stage).equal_to("published") if @model=="sources"
            paginate :page => 1, :per_page => maximumRecords
          end
        #else
          # Fulltext search
        #  solr_result = Sunspot.search(@model) do
         #   fulltext q
        #  end
        #end

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

    def self.examples
      [
       "Bach",
       "dc.creator=Bach",
       "dc.creator any Bach",
       "name=Bach and rism.siglum=D-Dl", 
       "changed<2017-02-01",
       "Bach OR siglum=D-Dl",
       "Bach, Johann Sebastian and Masses",
       'dc.creator="Bach, Johann NOT Sebastian" NOT siglum=D-Dl'
      ]
    end

    def to_solr(s)
      require 'cql_ruby'
      index_config = YAML.load_file("config/sru/service.config.yml")['index']
      token = CqlRuby::CqlLexer.new.tokenize(s)
      result = []
      subqueries = []
      token.chunk {|e| !(e =~ /^(AND|and|OR|or|NOT|not|PROX|prox)$/) }.each {|a| subqueries << a }
      subqueries.each_with_index do |query, index|
        if query[0]
          print query[1]
          if query[1].any? {|e| e =~ /^[=<>]/}
            puts "index"
            index_config.each do |k,v|
              if query[1][0] == k || query[1][0] == k.gsub(/^\w+\./ , "")
                if v['solr'].instance_of?(Array)
                  ary = []
                  v['solr'].each do |e|
                    ary << "#{e}_text=#{query[1][-1]}"
                  end
                  subqueries[index][1] = ["(#{ary.join(" OR ")})"]
                else
                  subqueries[index][1][0]="#{v['solr']}_#{v['type']}"
                end
                break
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
=begin
      fields.each do |field|
        index_config.each do |k,v|
          if field == k || field == k.gsub(/^\w+\./ , "")
            idx = token.index(field)
            # Expand array to cql query
            if v['solr'].instance_of?(Array)
              fulltext = []
            binding.pry
              v['solr'].each do |e|
                fulltext << "#{e}_text=#{token[token.index(field) + 2 ]}"
              end
              token[token.index(field)] = "(#{fulltext.join(" OR ")})"
              token[idx + 1]=""
              token[idx + 2]=""
            else
              if v['type'] == "d"
                date = Time.parse(token[idx + 2 ])
                token[idx + 2] = "#{date.strftime("%Y-%m-%d")}T23:59:59Z"
              end
              token[token.index(field)] = "#{v['solr']}_#{v['type']}"
            end
          end
        end
      end
=end
      #cql_string = token.flatten.join("")
      puts cql_string
      solr_string = CqlRuby::CqlParser.new.parse(cql_string).to_solr
      puts "#{cql_string} => #{solr_string}"
      return solr_string
    end


  end
end

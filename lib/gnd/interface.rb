# This module provides an Interface to the GND works

module GND

  # This class provides the main search functionality
  class Interface
    NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim", 'srw' => "http://www.loc.gov/zing/srw/", 'diag' => "http://www.loc.gov/zing/srw/diagnostic/", 'ucp' => "http://www.loc.gov/zing/srw/update/"}
    require 'open-uri'
    require 'net/http'

    SRU_PUSH_URL = "https://devel.dnb.de/sru_ru/"
    #SRU_READ_URL_AUTH = "https://services.dnb.de/sru/authorities"
    #SRU_READ_URL = "https://services.dnb.de/sru/cbs-appr"

    SRU_READ_URL_AUTH = "https://devel.dnb.de/sru/cbs-appr"
    SRU_READ_URL = "https://devel.dnb.de/sru/cbs-appr"

    def self.search(params, limit = 10)
        result = []
        xml = self.person_and_title_query(params, limit)

        # Loop on each record in the result list
        xml.xpath("//marc:record", NAMESPACE).each do |record|
            marc = MarcWorkNode.new(nil, "work_node_gnd")
            marc.load_from_xml(record)
            # Some items do not have a 100 tag
            next if !marc.first_occurance("100", "a")
            
            # Perform some conversion to the marc data - can return a message indicating why the record cannot be selected
            noSelectMsg = convert(marc)
            #puts marc
            id = get_id(marc)
            item = {marc: marc.to_json, description: get_description(marc), link: "https://d-nb.info/gnd/#{id}", label: "GND | #{id}", noSelectMsg: noSelectMsg, id: id} 
            result << item
        end
        return result
    end

    def self.push(marc_hash)
        m = MarcGndWork.new
        m.load_from_hash(marc_hash)

        action = m.get_id == "__TEMP__" ? :create : :replace

        return send_to_gnd(action, m.to_xml_record({}), m.get_id)
    end

    # post xml to gnd
    def self.send_to_gnd(action, xml, id=nil)
        server = SRU_PUSH_URL
        request_body = make_gnd_envelope(action, xml.to_s, id)
        call_result = nil
        diagnostic_messages = ""
        author = ""
        title = ""

        uri = URI.parse(server)
        post = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'text/xml')
        server = Net::HTTP.new(uri.host, uri.port)
        server.use_ssl = true
        server.start {|http|
            http.request(post, request_body) {|response|
                if response.code == "200"
                    puts response.body
                    response_body = Nokogiri::XML(response.body)

                    # Get all the messages if any
                    # Skip the TRACE message and collapse identical ones
                    diagnostic_messages = response_body.xpath("//diag:message", NAMESPACE).map{|e| e.content}.reject{|e| e.include?("TRACE")}.sort.uniq.join("; ")

                    # <ucp:operationStatus>success</ucp:operationStatus>
                    # should be "success" or "fail"
                    status = response_body.xpath("//ucp:operationStatus", NAMESPACE).first.content
                    # <ucp:recordIdentifier>ppn:XXX</ucp:recordIdentifier>
                    id = response_body.xpath("//ucp:recordIdentifier", NAMESPACE).first.content

                    # if all was ok, we return the ID from GND
                    if status == "success"
                        call_result = id

                        # one more! get the title and author
                        title = response_body.xpath("//srw:recordData/record/datafield[@tag='130']/subfield[@code='a']", NAMESPACE).first.content rescue title = ""
                        author = response_body.xpath("//srw:recordData/record/datafield[@tag='400']/subfield[@code='a']", NAMESPACE).first.content rescue author = ""
                    end
                end
            }
        }

        return call_result, diagnostic_messages, author, title
    end

    # Private method to wrap the xml into the envelope
    def self.make_gnd_envelope(action, data, id=nil)
        login = "#{Rails.application.credentials.gnd[:user]}/#{Rails.application.credentials.gnd[:password]}"
        recordId = id ? "<ucp:recordIdentifier>gnd:gnd#{id}</ucp:recordIdentifier>" : ""
        xml = <<-TEXT
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
        <ucp:updateRequest xmlns:ucp="http://www.loc.gov/zing/srw/update/" xmlns:srw="http://www.loc.gov/zing/srw/"  xmlns:diag="http://www.loc.gov/zing/srw/diagnostic/">
            <srw:version>1.0</srw:version>
            #{recordId}
            <ucp:action>info:srw/action/1/#{action}</ucp:action>
            <srw:record>
            <srw:recordPacking>xml</srw:recordPacking>
            <srw:recordSchema>MARC21-xml</srw:recordSchema>
            <srw:recordData>
            #{data}
            </srw:recordData>
            </srw:record>
            <srw:extraRequestData>
            <authenticationToken>#{login}</authenticationToken>
            </srw:extraRequestData>
        </ucp:updateRequest>
        </soap:Body>
    </soap:Envelope> 
        TEXT
        doc = Nokogiri::XML(xml,nil, 'UTF-8')
        return doc.to_xml
    end

    # Retrieve a single GND record using the GND Id
    def self.retrieve(id)
        result = nil
        query = SRU_READ_URL + "?version=1.1&operation=searchRetrieve&recordSchema=MARC21-xml&query=idn%3D#{id}"
        query_result = URI.open(query) rescue nil
        # Load the results
        xml = Nokogiri::XML(query_result)
       
        # Loop on each record in the result list
        xml.xpath("//marc:record", NAMESPACE).each do |record|
            marc = GndWork.new(nil, "gnd_work")
            marc.load_from_xml(record)
            result = marc
        end
        return result
    end

    # Query the GND with the query parameters and return an XML document with the results
    def self.query(term, index, auth, code = "", limit = 10)
        query = SRU_READ_URL_AUTH + "?version=1.1&operation=searchRetrieve&recordSchema=MARC21-xml&maximumRecords=#{limit}&query="
        # Code
        query += "BBG=#{auth}*"
        term.split.each do |word|
            query += " and #{index}=" + ERB::Util.url_encode(word + "*")
        end
        # Code - See https://wiki.dnb.de/download/attachments/90411323/entitaetenCodes.pdf
        query += " and COD=#{code}" if !code.empty?
        
        query_result = URI.open(query) rescue nil
        # Load the results
        xml = Nokogiri::XML(query_result)
    end

    # Query the GND with the query parameters and return an XML document with the results
    def self.person_and_title_query(params, limit = 30)
        query = SRU_READ_URL_AUTH + "?version=1.1&operation=searchRetrieve&recordSchema=MARC21-xml&maximumRecords=#{limit}&query="
        # We are searching the Work index
        query += "BBG=Tu*"

        # Add each token for the Person field
        if params[:composer]
            params[:composer].split.each do |word|
                query += " and PER=" + ERB::Util.url_encode(word)
            end
        end

        # And then each token for the Work title field
        if params[:title]
            params[:title].split.each do |word|
                query += " and WOE=" + ERB::Util.url_encode(word)
            end
        end

        # Code - See https://wiki.dnb.de/download/attachments/90411323/entitaetenCodes.pdf
        # We are searching the works
        query += " and COD=wim"
        
        query_result = URI.open(query) rescue nil
        # Load the results
        xml = Nokogiri::XML(query_result)
    end

    #####################################################
    ## Methods for converting a GND work to a WorkNode ##
    #####################################################

    def self.migrate_marc(marc)
        gnd_person_id = nil

        # replace "gnd" with "DNB" in $2
        node = marc.first_occurance("024", "2")
        node.content = "DNB" if node && node.content
        # adjust tag 100
        tag100 = marc.first_occurance("100")
        if tag100
            # merge all $m into one
            m_subtags = tag100.fetch_all_by_tag("m")
            m_subtags.drop(1).each do |m_subtag|
                m_subtags[0].content += ", #{m_subtag.content}" if m_subtag.content
                m_subtag.destroy_yourself
            end
            # merge all $n into one
            n_subtags = tag100.fetch_all_by_tag("n")
            n_subtags.drop(1).each do |n_subtag|
                n_subtags[0].content += " #{n_subtag.content}" if n_subtag.content
                n_subtag.destroy_yourself
            end
            # merge all $p into one
            p_subtags = tag100.fetch_all_by_tag("p")
            p_subtags.drop(1).each do |p_subtag|
                p_subtags[0].content += " #{p_subtag.content}" if p_subtag.content
                p_subtag.destroy_yourself
            end
        end

        # search for the corresponding composer in Muscat and set the 100 $0 accordingly
        person = nil
        tag500 = nil
        # first look for the 500 with $4 == kom1 in the GND record
        marc.each_by_tag("500") do |tag|
            tag.each_by_tag("4") do |t4|
                if t4.content and t4.content == "kom1"
                    tag500 = tag
                    break
                end
            end
        end
        # get the $0 subfield with the gnd uri
        if tag500
            tag500.each_by_tag("0") do |t0|
                if t0.content and t0.content.start_with?("https://d-nb.info/gnd/")
                    id = t0.content.gsub(/https:\/\/d-nb.info\/gnd\//, "")
                    id = "DNB:#{id}"
                    # retrieve the person pointing to it in Muscat (if any)
                    gnd_person_id = id
                    break
                end
            end
        end

        # remove all the 500 because they are not preserved in the WorkNode
        marc.by_tags("500").each {|t| t.destroy_yourself}

        return gnd_person_id
    end

    def self.convert(marc)
        person_id = migrate_marc(marc)

        person = find_person(person_id)
        if person
            marc.merge_person(person)
        else
            return "Composer not found in Muscat"
        end

        return ""
    end

    def self.get_id(marc)
        id = 0;
        if node = marc.first_occurance("024", "a")
            id = node.content.blank? ? "" : "#{node.content}"
        end
        return id
    end

    # returns an array with a composer and a formatted title
    def self.get_description(marc)
        # because the marc has been converted, we can now create a MarcWorkNode object out of it
        #marc_work_node = Object.const_get("MarcWorkNode").new(marc.to_marc)
        # and use its methods for getting the description
        return [marc.get_composer_name, marc.get_title]
    end

    # returns the Muscat person with the given DNB id
    def self.find_person(gnd_id)
        return nil if !gnd_id
        # make a solr search through field 024a
        query = Person.solr_search do 
            with("024a", gnd_id) if gnd_id
            paginate :page => 1, :per_page => Person.all.count
        end
        return (query.results and !query.results.empty?) ? query.results[0] : nil
    end
    
    ##########################
    ## Autocomplete queries ##
    ##########################
    
    def self.autocomplete(term, method, limit, options)
        if method == "person" 
            return autocomplete_person(term, limit, options)
        elsif method == "instrument" 
            return autocomplete_instrument(term, limit, options)
        elsif method == "form" 
            return autocomplete_form(term, limit, options)
        end
        {}
    end

    def self.autocomplete_person(term, limit, options)
        result = []
        xml = self.query(term, "PER", "Tp", "piz", limit)
        # Loop on each record in the result list
        xml.xpath("//marc:record", NAMESPACE).each do |record|
            item = {}
            node_001 = record.xpath("./marc:controlfield[@tag='001']", NAMESPACE).first
            next if !node_001
            item[:id] = node_001.text
            node_100a_val = record.xpath("./marc:datafield[@tag='100']/marc:subfield[@code='a']", NAMESPACE).first.text rescue "[missing]"
            item["person"] = node_100a_val
            node_100d_val = record.xpath("./marc:datafield[@tag='100']/marc:subfield[@code='d']", NAMESPACE).first.text rescue ""
            item["life_dates"] = node_100d_val
            item[:label] = "#{node_100a_val}"
            item[:label] += " (#{node_100d_val})" if !node_100d_val.empty?
            item[:label] += " – #{item[:id]}"
            result << item
        end
        result
    end

    def self.autocomplete_instrument(term, limit, options)
        result = []
        xml = self.query(term, "WOE", "Ts", "sab", limit)
        # Loop on each record in the result list
        xml.xpath("//marc:record", NAMESPACE).each do |record|
            item = {}
            node_001 = record.xpath("./marc:controlfield[@tag='001']", NAMESPACE).first
            next if !node_001
            item[:id] = node_001.text
            node_150a_val = record.xpath("./marc:datafield[@tag='150']/marc:subfield[@code='a']", NAMESPACE).first.text rescue "[missing]"
            item["instrument"] = node_150a_val
            item[:label] = "#{node_150a_val}"
            item[:label] += " – #{item[:id]}"
            result << item
        end
        result
    end

    def self.autocomplete_form(term, limit, options)
        result = []
        xml = self.query(term, "WOE", "Ts", "saz", limit)
        
        # Loop on each record in the result list
        xml.xpath("//marc:record", NAMESPACE).each do |record|
            item = {}
            node_001 = record.xpath("./marc:controlfield[@tag='001']", NAMESPACE).first
            next if !node_001
            item[:id] = node_001.text
            node_150a_val = record.xpath("./marc:datafield[@tag='150']/marc:subfield[@code='a']", NAMESPACE).first.text rescue "[missing]"
            item["form"] = node_150a_val
            item[:label] = "#{node_150a_val}"
            item[:label] += " – #{item[:id]}"
            result << item
        end
        result
    end

  end
end
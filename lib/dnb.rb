# This module provides an Interface to the DNB for marc records 

module DNB

  class Marc
    attr_accessor :marc, :response_body, :config, :muscat, :dnb
    NAMESPACE = {'xmlns:marc' => "http://www.loc.gov/MARC21/slim"}

    def initialize(record)
      @marc = record.marc
      @response_body = nil
      @config = YAML.load_file("#{Rails.root}/config/sru/dnb.config.yml")
      @muscat = Nokogiri::XML(@marc.to_xml,nil, 'UTF-8')
      @dnb = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
           xml['marc'].record(NAMESPACE) do
           end
      }.doc
 
    end

    def post
      request_body = _envelope(:create)
      uri = URI.parse(config["server"])
      post = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'text/xml')
      server = Net::HTTP.new(uri.host, uri.port)
      server.use_ssl = true
      server.start {|http|
        http.request(post, request_body) {|response|
          @response_body = response.body
        }
      }
    end

    def _datafield(tag)
      df = Nokogiri::XML::Node.new "datafield", dnb
      df['tag'], df['ind1'], df['ind2'] = tag, ' ', ' '
      return df
    end

    def _subfield(code, content)      
      sf = Nokogiri::XML::Node.new "subfield", dnb
      sf['code'] = code
      sf.content = content
      return sf
    end

    def muscat_to_dnb
      leader = Nokogiri::XML::Node.new "leader", dnb
      leader.content = "00000nz  a2200000oc 4500"
      cf = Nokogiri::XML::Node.new "controlfield", dnb
      cf['tag'] = '008'
      cf.content = "160812n||aznnnaabn           | ana    |c"
      dnb.root << leader
      dnb.root << cf

      df = _datafield('075') 
      [_subfield('b', 'wim'), _subfield('2', 'gndspec')].each {|sf| df << sf}
      dnb.root << df
      
      df = _datafield('075') 
      [_subfield('b', 'u'), _subfield('2', 'gndgen')].each {|sf| df << sf}
      dnb.root << df
      
      df = _datafield('079') 
      [_subfield('a', 'g'), _subfield('q', 'm'), _subfield('q', 'f')].each {|sf| df << sf}
      dnb.root << df

      config['extract'].each do |tag|
        muscat.xpath("//marc:datafield[@tag='#{tag}']", NAMESPACE).each do |df|
          dnb.root << df
        end
      end
      dnb.xpath("//marc:subfield[@code='0']").remove
      return dnb
    end

    def put

    end

    def _envelope(action)
      if action == :create
        data = muscat_to_dnb
      else
        data = ""
      end
      xml = <<-TEXT
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <ucp:updateRequest xmlns:ucp="http://www.loc.gov/zing/srw/update/" xmlns:srw="http://www.loc.gov/zing/srw/"  xmlns:diag="http://www.loc.gov/zing/srw/diagnostic/">
            <srw:version>1.0</srw:version>
            <ucp:action>info:srw/action/1/#{action}</ucp:action>
            <srw:record>
            <srw:recordPacking>xml</srw:recordPacking>
            <srw:recordSchema>MARC21-xml</srw:recordSchema>
              <srw:recordData>
      #{dnb.root.to_s}
              </srw:recordData>
            </srw:record>
            <srw:extraRequestData>
              <authenticationToken>#{Rails.application.credentials.dnb[:login]}</authenticationToken>
            </srw:extraRequestData>
          </ucp:updateRequest>
        </soap:Body>
      </soap:Envelope> 
      TEXT
      doc = Nokogiri::XML(xml,nil, 'UTF-8')
      return doc.to_xml
    end

    def _prepare_post
      # add aministration nodes
      new_075a = MarcNode.new(Work, "075", "", "##")
      new_075a.add(MarcNode.new(Work, "b", "wim", nil))
      new_075a.add(MarcNode.new(Work, "2", "gndspec", nil))
      new_075a.sort_alphabetically
      marc.root.children.insert(marc.get_insert_position("075"), new_075a)
      new_075b = MarcNode.new(Work, "075", "", "##")
      new_075b.add(MarcNode.new(Work, "b", "u", nil))
      new_075b.add(MarcNode.new(Work, "2", "gndgen", nil))
      new_075b.sort_alphabetically
      marc.root.children.insert(marc.get_insert_position("075"), new_075b)
      new_079 = MarcNode.new(Work, "079", "", "##")
      new_079.add(MarcNode.new(Work, "a", "g", nil))
      new_079.add(MarcNode.new(Work, "q", "m", nil))
      new_079.add(MarcNode.new(Work, "q", "f", nil))
      new_079.sort_alphabetically
      marc.root.children.insert(marc.get_insert_position("079"), new_079)
      new_leader = MarcNode.new(Work, "000", "00000nz  a2200000oc 4500", "")
      marc.root.children.insert(marc.get_insert_position("000"), new_leader)
      new_008 = MarcNode.new(Work, "008", "160812n||aznnnaabn           | ana    |c", "")
      marc.root.children.insert(marc.get_insert_position("008"), new_008)

      # removing nodes
      marc.root.fetch_first_by_tag("001").destroy_yourself
      marc.root.fetch_all_by_tag("024").each do |tag|
        puts tag
        tag.destroy_yourself
      end
      marc.root.children.each do |tag|
        zero = tag.fetch_first_by_tag("0")
        zero.destroy_yourself if zero
      end
      doc = Nokogiri::XML(marc.to_xml, nil, 'UTF-8').root.to_s
      return doc
    end
  end
end

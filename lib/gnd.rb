# This module provides an Interface to the GND for marc records 

module GND

  class Interface
    attr_accessor :response_body, :config, :muscat, :gnd, :record, :gnd_ids
    NAMESPACE = {'xmlns:marc' => "http://www.loc.gov/MARC21/slim", 'xmlns:soap' => "http://schemas.xmlsoap.org/soap/envelope/",
                 'xmlns:ucp'=> "http://www.loc.gov/zing/srw/update/", 'xmlns:diag'=> "http://www.loc.gov/zing/srw/diagnostic/"
    }

    def initialize(record)
      @record = record
      @gnd_ids = record.marc.gnd_ids
      @response_body = nil
      @config = YAML.load_file("#{Rails.root}/config/sru/gnd.config.yml")
      @muscat = Nokogiri::XML(@record.marc.to_xml,nil, 'UTF-8')
      @gnd = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
           xml['marc'].record(NAMESPACE) do
           end
      }.doc
      @gnd.root['type']="Authority"
    end

    def post
      request_body = _envelope(:create)
      uri = URI.parse(config["server"])
      post = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'text/xml')
      server = Net::HTTP.new(uri.host, uri.port)
      server.use_ssl = true
      server.start {|http|
        http.request(post, request_body) {|response|
          puts response.body
          @response_body = Nokogiri::XML(response.body)
        }
      }
    end
   
    # create a gnd marc from muscat
    def convert_to_gnd
      leader = Nokogiri::XML::Node.new "leader", gnd
      leader.content = "00000nz  a2200000oc 4500"
      cf = Nokogiri::XML::Node.new "controlfield", gnd
      cf['tag'] = '008'
      cf.content = "160812n||aznnnaabn           | ana    |c"
      gnd.root << leader
      gnd.root << cf
      # adding some required administration fields
      df = _datafield('042') 
      [_subfield('a', 'gnd3')].each {|sf| df << sf}
      gnd.root << df

      df = _datafield('075') 
      [_subfield('b', 'wim'), _subfield('2', 'gndspec')].each {|sf| df << sf}
      gnd.root << df
      
      df = _datafield('075') 
      [_subfield('b', 'u'), _subfield('2', 'gndgen')].each {|sf| df << sf}
      gnd.root << df
      
      df = _datafield('079') 
      [_subfield('a', 'g'), _subfield('q', 'm'), _subfield('q', 'f')].each {|sf| df << sf}
      gnd.root << df

      # copy muscat nodes to gnd
      config['gnd'].each do |tag|
        muscat.xpath("//marc:datafield[@tag='#{tag}']", NAMESPACE).each do |df|
          gnd.root << df.dup
        end
      end
      gnd.xpath("//marc:subfield[@code='0']").remove
      
      # required 500 related composer node by GND
      n = gnd.xpath("//marc:datafield[@tag='100']", NAMESPACE)[0].dup
      n["tag"] = '500'
      composer_id = record.person.marc.gnd_ids.first rescue nil
      if composer_id
        n << _subfield("0", "(DE-588)#{composer_id}")
        n << _subfield("0", "https://d-nb.info/gnd/#{composer_id}")
      end
      n << _subfield("4", "kom1")
      n << _subfield("4", "https://d-nb.info/standards/elementset/gnd#firstComposer")
      n << _subfield("w", "r")
      n << _subfield("i", "Komponist1")
      n << _subfield("e", "Komponist1")
      n.xpath("marc:subfield[@code='t']", NAMESPACE).remove
      gnd.root << n
      # prettify
      @gnd = Nokogiri.XML(gnd.to_s) do |config|
        config.default_xml.noblanks
      end
    end

    # TODO the updating
    def put

    end

    def message
      @response_body.xpath("//diag:message", GND::Interface::NAMESPACE).map{|e| e.content}.join("; ") rescue nil
    end

    def _envelope(action)
      if action == :create
        convert_to_gnd
        data = gnd.root.to_s
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
      #{data}
              </srw:recordData>
            </srw:record>
            <srw:extraRequestData>
              <authenticationToken>#{Rails.application.credentials.gnd[:login]}</authenticationToken>
            </srw:extraRequestData>
          </ucp:updateRequest>
        </soap:Body>
      </soap:Envelope> 
      TEXT
      doc = Nokogiri::XML(xml,nil, 'UTF-8')
      return doc.to_xml
    end

    private 

    def _datafield(tag, ind1=' ', ind2=' ')
      df = Nokogiri::XML::Node.new "datafield", gnd
      df['tag'], df['ind1'], df['ind2'] = tag, ind1, ind2
      return df
    end

    def _subfield(code, content)      
      sf = Nokogiri::XML::Node.new "subfield", gnd
      sf['code'] = code
      sf.content = content
      return sf
    end
 

  end
end

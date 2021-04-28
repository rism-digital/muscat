# This module provides an Interface to the GND for marc records 

module DNB

  class Service
    NAMESPACE = {'xmlns:marc' => "http://www.loc.gov/MARC21/slim", 'xmlns:soap' => "http://schemas.xmlsoap.org/soap/envelope/",
                 'xmlns:ucp'=> "http://www.loc.gov/zing/srw/update/", 'xmlns:diag'=> "http://www.loc.gov/zing/srw/diagnostic/"
    }
    CONFIG  = YAML.load_file("#{Rails.root}/config/sru/gnd.config.yml")

    attr_accessor :gnd, :muscat, :interface
    def initialize(record)
      @muscat = Muscat.new(record)
      @gnd = GND.new()
      @gnd.ids = record.marc.gnd_ids
      if @gnd.ids
        @gnd.query
      end
      @interface = Interface.new
    end

    # create a new gnd record if there is no gnd.id, else update the existing record
    def synchronize
      # TODO add the gnd.id to muscat.marc 024
      unless gnd.ids
        gnd.xml = muscat.to_gnd.root
        interface.post(:create, gnd.xml)
        gnd.ids << interface.status.split("PPN: ").last
      else
        gnd.xml = muscat.to_gnd(gnd.ids.first, gnd.timestamp).root
        interface.post(:replace, gnd.xml, gnd.ids.first)
      end
    end

    class GND
      attr_accessor :xml, :ids, :timestamp
      def initialize
        @xml = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
           xml['marc'].record(NAMESPACE) do
           end
          }.doc
        @xml.root['type']="Authority"
        @ids = nil
        @timestamp = nil
      end

      def query
        return nil if ids.empty?
        id = ids.first
        uri = URI.parse("#{CONFIG["search_server"]}authorities?version=1.1&operation=searchRetrieve&query=NID=#{id}&recordSchema=MARC21-xml")
        get = Net::HTTP::Get.new(uri)
        server = Net::HTTP.new(uri.host, uri.port)
        server.use_ssl = true
        server.start {|http|
          http.request(get) {|response|
            @xml = Nokogiri::XML(response.body).xpath("//marc:record", NAMESPACE)
            @timestamp = @xml.xpath("marc:controlfield[@tag='005']", NAMESPACE).text
            puts response.body
          }
        }
      end
    end

    class Muscat
      attr_accessor :record, :xml
      def initialize(record)
        @record = record
        @xml = Nokogiri::XML(@record.marc.to_xml,nil, 'UTF-8')
      end

      # create a gnd marc from muscat xml
      # TODO gnd drops 100$m and 100$n
      def to_gnd(id=nil, timestamp=nil)        
        gnd = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
           xml['marc'].record(NAMESPACE) do
           end
          }.doc
        gnd.root['type']="Authority"
        node = DNB::Service::XMLTools.new(gnd)
 
        leader = Nokogiri::XML::Node.new "leader", gnd
        leader.content = "00000nz  a2200000oc 4500"
        gnd.root << leader

        if id && timestamp
          c1 = Nokogiri::XML::Node.new "controlfield", gnd
          c1['tag'] = '001'
          c1.content = "#{id}"
          gnd.root << c1
          c5 =  Nokogiri::XML::Node.new "controlfield", gnd
          c5['tag'] = '005'
          c5.content = "#{timestamp}"
          gnd.root << c5
        end

        cf = Nokogiri::XML::Node.new "controlfield", gnd
        cf['tag'] = '008'
        cf.content = "160812n||aznnnaabn           | ana    |c"
        gnd.root << cf
        # adding some required administration fields
        df = node.datafield('042') 
        [node.subfield('a', 'gnd3')].each {|sf| df << sf}
        gnd.root << df

        df = node.datafield('075') 
        [node.subfield('b', 'wim'), node.subfield('2', 'gndspec')].each {|sf| df << sf}
        gnd.root << df

        df = node.datafield('075') 
        [node.subfield('b', 'u'), node.subfield('2', 'gndgen')].each {|sf| df << sf}
        gnd.root << df

        df = node.datafield('079') 
        [node.subfield('a', 'g'), node.subfield('q', 'm'), node.subfield('q', 'f')].each {|sf| df << sf}
        gnd.root << df

        # copy muscat nodes to gnd
        CONFIG['gnd'].each do |tag|
          xml.xpath("//marc:datafield[@tag='#{tag}']", NAMESPACE).each do |df|
            gnd.root << df.dup
          end
        end
        gnd.xpath("//marc:subfield[@code='0']").remove

        # required 500 datafield related composer node by GND
        n = gnd.xpath("//marc:datafield[@tag='100']", NAMESPACE)[0].dup
        n["tag"] = '500'
        composer_id = record.person.marc.gnd_ids.first rescue nil
        if composer_id
          n << node.subfield("0", "(DE-588)#{composer_id}")
          n << node.subfield("0", "https://d-nb.info/gnd/#{composer_id}")
        end
        n << node.subfield("4", "kom1")
        n << node.subfield("4", "https://d-nb.info/standards/elementset/gnd#firstComposer")
        n << node.subfield("w", "r")
        n << node.subfield("i", "Komponist1")
        n << node.subfield("e", "Komponist1")
        n.xpath("marc:subfield[@code='t']", NAMESPACE).remove
        gnd.root << n
        # prettifing
        gnd = Nokogiri.XML(gnd.to_s) do |config|
          config.default_xml.noblanks
        end
        return gnd
      end
    end

    class Interface
      attr_accessor :response_body, :status
      def initialize
        @response_body = nil
        @status = nil
      end

      # post xml to gnd
      def post(action, xml, id=nil)
        request_body = _envelope(action, xml.to_s, id)
        uri = URI.parse(CONFIG["server"])
        post = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'text/xml')
        server = Net::HTTP.new(uri.host, uri.port)
        server.use_ssl = true
        server.start {|http|
          http.request(post, request_body) {|response|
            puts response.body
            @response_body = Nokogiri::XML(response.body)
            @status = @response_body.xpath("//diag:message", NAMESPACE).map{|e| e.content}.join("; ") rescue nil
            puts response_body
            #gnd.xml =  @response_body.xpath("//record")
          }
        }
      end

      def _envelope(action,data, id=nil)
        xml = <<-TEXT
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <ucp:updateRequest xmlns:ucp="http://www.loc.gov/zing/srw/update/" xmlns:srw="http://www.loc.gov/zing/srw/"  xmlns:diag="http://www.loc.gov/zing/srw/diagnostic/">
            <srw:version>1.0</srw:version>
            #{"<ucp:recordIdentifier>gnd:gnd" + id + "</ucp:recordIdentifier>" if id}
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
    end

 
    class XMLTools
      attr_accessor :node
      def initialize(node)
        @node = node
      end
      def datafield(tag, ind1=' ', ind2=' ')
        df = Nokogiri::XML::Node.new "datafield", node
        df['tag'], df['ind1'], df['ind2'] = tag, ind1, ind2
        return df
      end

      def subfield(code, content)      
        sf = Nokogiri::XML::Node.new "subfield", node
        sf['code'] = code
        sf.content = content
        return sf
      end
    end


  end
end

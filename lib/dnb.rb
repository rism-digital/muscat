# This module provides an Interface to the GND for marc records 
module DNB

  # Top class to manage gnd <-> muscat communiction with three nested classes and one helper class
  class Service
    NAMESPACE = {'xmlns:marc' => "http://www.loc.gov/MARC21/slim", 'xmlns:soap' => "http://schemas.xmlsoap.org/soap/envelope/",
                 'xmlns:ucp'=> "http://www.loc.gov/zing/srw/update/", 'xmlns:diag'=> "http://www.loc.gov/zing/srw/diagnostic/"
    }
    CONFIG  = YAML.load_file("#{Rails.root}/config/sru/gnd.config.yml")

    attr_accessor :gnd, :muscat, :interface

    # Building the muscat xml, the gnd xml if linked and the interface
    def initialize(record)
      @muscat = Muscat.new(record)
      @gnd = GND.new()
      @gnd.id = record.marc.gnd_ids.empty? ? nil : record.marc.gnd_ids.first
      if @gnd.id
        @gnd.query
      end
      @interface = Interface.new
    end

    # create a new gnd record if there is no gnd.id, else update the existing record
    def synchronize
      unless gnd.id
        gnd.xml = muscat.to_gnd.root
        interface.post(:create, gnd.xml)
        gnd.id = interface.status.split("PPN: ").last
        marc = muscat.record.marc
        # Adding the gnd id to the muscat record
        new_024 = MarcNode.new(Work, "024", "", "##")
        ip = marc.get_insert_position("024")
        new_024.add(MarcNode.new(Work, "a", gnd.id, nil))
        new_024.add(MarcNode.new(Work, "2", "DNB", nil))
        marc.root.children.insert(ip, new_024)
        muscat.record.marc = marc
        muscat.record.save
      else
        gnd.xml = muscat.to_gnd(gnd.id, gnd.timestamp).root
        interface.post(:replace, gnd.xml, gnd.id)
      end
    end

    # Container for the GND xml
    class GND
      attr_accessor :xml, :id, :timestamp
      def initialize
        @xml = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
           xml['marc'].record(NAMESPACE) do
           end
          }.doc
        @xml.root['type']="Authority"
        @id = nil
        @timestamp = nil
      end

      def query
        return nil unless id
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

      def to_s
        xml.to_s if id
      end
    end

    # Container for the Muscat xml
    class Muscat
      attr_accessor :record, :xml
      def initialize(record)
        @record = record
        xml = Nokogiri::XML(@record.marc.to_xml,nil, 'UTF-8')
        @xml = Nokogiri.XML(xml.to_s) do |config|
          config.default_xml.noblanks
        end
 
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

        df = node.datafield('035') 
        [node.subfield('a', "(DE-633)#{record.id}")].each {|sf| df << sf}
        gnd.root << df

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
            df.xpath("marc:subfield[@code='0']").remove
            if tag == "100"
              no = df.xpath("marc:subfield[@code='n']").first.content rescue nil
              if no
                df383 = node.datafield('383')
                [node.subfield('b', no)].each {|sf| df383 << sf}
                gnd.root << df383
              end
              no = df.xpath("marc:subfield[@code='r']").first.content rescue nil
              if no
                df384 = node.datafield('384')
                [node.subfield('a', no)].each {|sf| df384 << sf}
                gnd.root << df384
              end
            end

            if tag == "548"
              [node.subfield('4', 'dats')].each {|sf| df << sf}
              [node.subfield('4', 'https://d-nb.info/standards/elementset/gnd#dateOfProduction')].each {|sf| df << sf}
              [node.subfield('5', 'DE-633')].each {|sf| df << sf}
              [node.subfield('w', 'r')].each {|sf| df << sf}
              [node.subfield('i', 'Erstellungszeit')].each {|sf| df << sf}
            end

            if tag == "670"
              no = df.xpath("marc:subfield[@code='b']").first.content rescue nil
              if no
                [node.subfield('u', no)].each {|sf| df << sf}
                df.xpath("marc:subfield[@code='w']").remove
                df.xpath("marc:subfield[@code='b']").remove
                df.xpath("marc:subfield[@code='u']").remove
              end
            end
            gnd.root << df.dup
          end
        end
        #gnd.xpath("//marc:subfield[@code='0']").remove

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
      
      def to_s
        xml.to_s
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
        puts request_body
        uri = URI.parse(CONFIG["server"])
        post = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'text/xml')
        server = Net::HTTP.new(uri.host, uri.port)
        server.use_ssl = true
        server.start {|http|
          http.request(post, request_body) {|response|
            puts response.body
            @response_body = Nokogiri::XML(response.body)
            @status = @response_body.xpath("//diag:message", NAMESPACE).map{|e| e.content}.join("; ") rescue nil
            #gnd.xml =  @response_body.xpath("//record")
          }
        }
      end

      # Private method to wrap the xml into the envelope
      def _envelope(action,data, id=nil)
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

    # Helper class for easy building xml nodes 
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

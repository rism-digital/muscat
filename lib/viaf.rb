# This module provides an Interface to the VIAF 

module Viaf

  # A List of VIAF providers sorted by rank

  # This class provides the main search functionality
  class Interface
    NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
    require 'open-uri'

    def self.search(term, model)
      providers = YAML::load(File.open("config/viaf/#{model.to_s.downcase}.yml"))
      result = []
      query = JSON.load(open(URI.escape("http://viaf.org/viaf/AutoSuggest?query="+term)))
      if model.to_s == 'Person'
        r = query["result"].map{|e| e if e['nametype']=='personal'}.compact
      else
        #TODO adopt for other marc classes
        r = query["result"].map{|e| e if e['nametype']=='personal'}.compact
      end
      provider_doc = ""
      r.each do |record|
        providers.keys.each do |provider|
          puts provider
          if record[provider.downcase]
            provider_id=record[provider.downcase]
          else
            next
          end
          provider_url="http://viaf.org/processed/#{provider}%7C#{provider_id}?httpAccept=application/xml"
          links = JSON.load(open(URI.escape("http://viaf.org/viaf/#{record["viafid"]}/justlinks.json")))
          provider_doc = Nokogiri::XML(open(provider_url))
          # TODO IMPROVE inject methods
          provider_doc.xpath('//marc:controlfield[@tag="001"]', NAMESPACE).first.content = record["viafid"]
          node_24 = provider_doc.xpath('//marc:datafield[@tag="100"]', NAMESPACE)
          provider_doc.xpath('//marc:datafield[@tag="024"]', NAMESPACE).remove
          node_24.first.add_previous_sibling(self.build_provider_node(provider_doc.root, "VIAF", record["viafid"]))
          node_24.first.add_previous_sibling(self.build_provider_node(provider_doc.root, provider, provider_id))
          if links["WKP"]
            node_24.first.add_previous_sibling(self.build_provider_node(provider_doc.root, "WKP", links["WKP"][0]))
          end

         if provider_doc.xpath('//marc:datafield[@tag="100"]', NAMESPACE).empty?
            next
          else
            xslt  = Nokogiri::XSLT(File.read('config/viaf/' + providers[provider]))
            doc = xslt.transform(provider_doc)
            # Escaping for json
            doc = doc.to_s.gsub(/'/, "&apos;")
            marc = Object.const_get("Marc#{model.to_s.capitalize}").new(doc)
            result << marc.to_json
            break
          end
        end
      end
      return result
    end


    def self.build_provider_node(parent, provider, id)
          tag = Nokogiri::XML::Node.new "mx:datafield", parent
          tag['tag'] = '024'
          tag['ind1'] = '7'
          tag['ind2'] = ' '
          sfa = Nokogiri::XML::Node.new "mx:subfield", parent
          sfa['code'] = 'a'
          sfa.content = id
          sf2 = Nokogiri::XML::Node.new "mx:subfield", parent
          sf2['code'] = '2'
          sf2.content = provider
          tag << sfa << sf2
          return tag
    end


    def self.xsl_test
      xml = File.open("config/viaf/test.xml") { |f| Nokogiri::XML(f)  }
      xslt  = Nokogiri::XSLT(File.read('config/viaf/person_bnf.xsl'))
      doc = xslt.transform(xml)
      puts doc.to_s.split("\n")[0..20].join("\n")
    end
  end
end

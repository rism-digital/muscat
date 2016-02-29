# This module provides an Interface to the VIAF 

module Viaf

  # A List of VIAF providers sorted by rank
  SELECT_PROVIDER = YAML::load(File.open("config/viaf/person.yml"))

  # This class provides the main search functionality
  class Interface
    NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
    require 'open-uri'

    def self.search(term, model)
      result = []
      query = JSON.load(open(URI.escape("http://viaf.org/viaf/AutoSuggest?query="+term)))
      r = query["result"].map{|e| e if e['nametype']=='personal'}.compact
      provider_doc = ""
      r.each do |record|
        SELECT_PROVIDER.each do |provider|
          puts provider
          if record[provider.downcase]
            provider_id=record[provider.downcase]
          else
            next
          end
          provider_url="http://viaf.org/processed/#{provider}%7C#{provider_id}?httpAccept=application/xml"
          provider_doc = Nokogiri::XML(open(provider_url))
          # IMPROVE inject methods
          provider_doc.xpath('//marc:controlfield[@tag="001"]', NAMESPACE).first.content = record["viafid"]
          node_24 = provider_doc.xpath('//marc:datafield[@tag="024"]', NAMESPACE)
          tag_024 = Nokogiri::XML::Node.new "mx:datafield", provider_doc.root
          tag_024['tag'] = '024'
          tag_024['ind1'] = '7'
          tag_024['ind2'] = ' '
          sfa = Nokogiri::XML::Node.new "mx:subfield", provider_doc.root
          sfa['code'] = 'a'
          sfa.content = record["viafid"]
          sf2 = Nokogiri::XML::Node.new "mx:subfield", provider_doc.root
          sf2['code'] = '2'
          sf2.content = "VIAF"
          tag_024 << sfa << sf2
          if node_24.empty?
            provider_doc.root << tag_024
          else
            node_24.first.add_previous_sibling(tag_024)
          end
          puts record["displayForm"]
          if provider_doc.xpath('//marc:datafield[@tag="100"]', NAMESPACE).empty?
            next
          else
            xslt  = Nokogiri::XSLT(File.read('config/viaf/person_dnb.xsl'))
            doc = xslt.transform(provider_doc)
            marc = MarcPerson.new(doc.to_s)
            result << marc.to_json
            break
          end
        end
      end
      return result
    end
  end
end

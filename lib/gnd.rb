# This module provides an Interface to the GND works

module GND

  # This class provides the main search functionality
  class Interface
    NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim", 'srw' => "http://www.loc.gov/zing/srw/" }
    require 'open-uri'
    require 'net/http'
    # Make sure queries with no result (less than 10K) are not returned as StringIO by open-uri
    OpenURI::Buffer::StringMax = 0

    def self.search(term, model)
        result = []
        begin
            query = open(URI.escape(self.build_query(term, model)))
          rescue 
            return "ERROR connecting GND AutoSuggest"
        end

        # Load the XSLT to transform the MarcXML into Marc
        xslt  = Nokogiri::XSLT(File.read('config/gnd/' + 'work_node_dnb.xsl'))
        # Load the results
        xml = Nokogiri::XML(open(query))
        # Loop on each record in the result list
        xml.xpath("//marc:record", NAMESPACE).each do |record|

            record_xml = Nokogiri.parse(record.to_s)
            # Transform MarcXML to Marc
            doc = xslt.transform(record_xml)
            # Some normalization
            doc = doc.to_s.gsub(/'/, "&apos;").unicode_normalize
            marc = Object.const_get("Marc").new("work_node_gnd", doc)
            # Perform some conversion to the marc data
            convert(marc)
            result << marc.to_json
        end
        if result.empty?
            return "Sorry, no work results were found in GND!"
        end
        return result
    end

    def self.build_query(term, model)
        query = "https://services.dnb.de/sru/authorities?version=1.1&operation=searchRetrieve&recordSchema=MARC21-xml&query="
        # Code for musical works
        query += "COD=wim"
        term.split.each do |word|
            query += " and WOE=" + word
        end
        puts query
        # Work index
        query += " and BBG=Tu*"
        query
    end

    def self.convert(marc)
        # replace "gnd" with "DNB" in $2
        node = marc.first_occurance("024", "2")
        node.content = "DNB" if node && node.content
    end

  end
end

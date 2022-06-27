# This module provides an Interface to the GND works

module GND

  # This class provides the main search functionality
  class Interface
    NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim", 'srw' => "http://www.loc.gov/zing/srw/" }
    require 'open-uri'
    require 'net/http'

    def self.search(term, model)
        result = []
        begin
            query = URI.open(self.build_query(term, model))
        rescue 
            return "ERROR connecting GND AutoSuggest"
        end

        # Load the XSLT to transform the MarcXML into Marc
        xslt  = Nokogiri::XSLT(File.read('config/gnd/' + 'work_node_dnb.xsl'))
        # Load the results
        xml = Nokogiri::XML(query)

        # Loop on each record in the result list
        xml.xpath("//marc:record", NAMESPACE).each do |record|

            record_xml = Nokogiri.parse(record.to_s)
            # Transform MarcXML to Marc
            doc = xslt.transform(record_xml)
            # Some normalization
            doc = doc.to_s.gsub(/'/, "&apos;").unicode_normalize
            marc = Object.const_get("Marc").new("work_node_gnd", doc)

            # Some items do not have a 100 tag
            next if !marc.first_occurance("100", "a")
            
            # Perform some conversion to the marc data
            convert(marc)
            id = get_id(marc)
            item = {marc: marc.to_json, description: get_description(marc), link: "https://d-nb.info/gnd/#{id}", label: "GND | #{id}" }
            result << item
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
            query += " and WOE=" + ERB::Util.url_encode(word)
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
        tag100 = marc.first_occurance("100")
        # move $p to $n
        tag100.each_by_tag("p") do |p|
            p.tag = "n"
        end
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
        marc_work_node = Object.const_get("MarcWorkNode").new(marc.to_marc)
        # and use its methods for getting the description
        return [marc_work_node.get_composer_name, marc_work_node.get_title]
    end

  end
end

# This module provides an Interface to the VIAF 

module Viaf
  
  # A List of VIAF providers sorted by rank
  SELECT_PROVIDER = %w(DNB BNF LC ICCU ISNI BNE WKP NKC NLP SWNL BAV)
  
  # This class provides the main search functionality
  class Interface
    NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
    require 'rexml/document'
    include REXML
    require 'open-uri'

    # Sends a http request to the API and returns an array of MarcNodes
    def self.search(term, model)
      result = []
      zing = {'ns1'=> "http://www.loc.gov/zing/srw/"}
      case model.to_s
      when "Person"
        cql = "local.mainHeadingEl+all+"
      else
        cql = "cql.any+all+"
      end
      cql = "local.mainHeadingEl+all+"
      sort = "&sortKeys=holdingscount"
      recordSchema = "&recordSchema=info:srw/schema/1/marcxml-v1.1"
      max = "&maximumRecords=10"
      x1 = "http://viaf.org/viaf/search?query=#{cql}%22#{URI::encode(term)}%22&httpAccept=application/xml#{sort}#{max}#{recordSchema}"
      doc = Nokogiri::XML(open(x1))
      records = doc.xpath("//ns1:records/ns1:record/ns1:recordData/*", zing)
      records.each do |record|
        #OPTIMIZE probably better to use a MarcNodeBuilder
        node = MarcNode.new(model)
        r = Nokogiri::XML(record.to_xml)
        viaf_id = r.xpath('//marc:controlfield[@tag="001"]', NAMESPACE)[0].content[4..-1]
        node.add(MarcNode.new(model, "001", viaf_id))
        node.add(MarcNode.new(model, "024"))
        node.fetch_first_by_tag("024").add(MarcNode.new(model, "a", viaf_id))
        node.fetch_first_by_tag("024").add(MarcNode.new(model, "2", "VIAF"))
        SELECT_PROVIDER.each do |provider|
          tag100 = r.xpath('//marc:datafield[@tag="700"]/marc:subfield[@code="0"][contains(text(),"' + provider + '")]/..', NAMESPACE)[0]
          if tag100 && tag100.xpath('marc:subfield', NAMESPACE).size >= 2
            node.add(MarcNode.new(model, "100"))
            tag = tag100.xpath('marc:subfield[@code="a"]', NAMESPACE)
            node.fetch_first_by_tag("100").add(MarcNode.new(model, "a", tag.first.content)) unless tag.empty?
            tag = tag100.xpath('marc:subfield[@code="d"]', NAMESPACE)
            node.fetch_first_by_tag("100").add(MarcNode.new(model, "d", tag.first.content)) unless tag.empty?
            tag = tag100.xpath('marc:subfield[@code="0"]', NAMESPACE)
            node.fetch_first_by_tag("100").add(MarcNode.new(model, "0", tag.first.content)) unless tag.empty?
          else
            next
          end
          break if node.fetch_first_by_tag("100") 
        end
        if node.fetch_first_by_tag("100") 
          marc_json = {"leader" => "01471cjm a2200349 a 4500", "fields" => []}
          node.children.each do |k|
            marc_json["fields"] << k.to_json
          end
          result << marc_json
        end
      end
      return result
    end
  end
end

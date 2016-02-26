# This module provides an Interface to the VIAF 

module Viaf
  
  # A List of VIAF providers sorted by rank
  SELECT_PROVIDER = %w(DNB BNF LC ICCU ISNI BNE WKP NKC NLP SWNL BAV)
  # Requested fields
  TAGS = {"100" => %w(a d 0), "374" => %w(a)}
  # VIAF XML has other tag definitions than ours, so we have to give the target
  VIAF_CONVERTER = {"100" => "700", "374" => "941"}
  
  # This class provides the main search functionality
  class Interface
    NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
    require 'rexml/document'
    include REXML
    require 'open-uri'

    # Sends a http request to the API and returns an array of MarcNodes
    # Another approach could be to select the specific node from the viaf cluster and then take the fields, see below
    # Advantage 1: we can use only one scheme which is more standard (eg LC or DNB)
    # Advantage 2: in the nodes there are more information
    # Disadvantage: needs more time and rescources
    #
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

        # for the alternative approach
        #dnb_node=r.xpath('//marc:datafield[@tag="700"]/marc:subfield[@code="0"][contains(text(),"DNB")]/..', NAMESPACE)
        #dnb=dnb_node.xpath('marc:subfield[@code="0"]/text()', NAMESPACE).to_s.gsub("(", "").gsub(")", "|")
        #dnb_url="http://viaf.org/processed/#{dnb.gsub("|", "%7C")}?httpAccept=application/xml" 
        #begin
        #  dnb_doc = Nokogiri::XML(open(dnb_url))
        #  puts dnb_doc
        #rescue
        #  puts "ERROR finding node"
        #end

        viaf_id = r.xpath('//marc:controlfield[@tag="001"]', NAMESPACE)[0].content[4..-1]
        node.add(MarcNode.new(model, "001", viaf_id))
        node.add(MarcNode.new(model, "024"))
        node.fetch_first_by_tag("024").add(MarcNode.new(model, "a", viaf_id))
        node.fetch_first_by_tag("024").add(MarcNode.new(model, "2", "VIAF"))
        SELECT_PROVIDER.each do |provider|
          TAGS.each do |key,v|
            break if node.fetch_first_by_tag(key)
            # HACK for diverse 941 authority code in $2
            if key == '374'
              tag = r.xpath('//marc:datafield[@tag="' + VIAF_CONVERTER[key] + '"]/marc:subfield[@code="2"][contains(text(),"' + provider + '")]/..', NAMESPACE)[0]
            else
              tag = r.xpath('//marc:datafield[@tag="' + VIAF_CONVERTER[key] + '"]/marc:subfield[@code="0"][contains(text(),"' + provider + '")]/..', NAMESPACE)[0]
            end
            v.each do |code|
              if tag && tag.xpath('marc:subfield', NAMESPACE).size >= 2
                node.add(MarcNode.new(model, key)) unless node.fetch_first_by_tag(key)
                subfield = tag.xpath('marc:subfield[@code="' + code + '"]', NAMESPACE)
                node.fetch_first_by_tag(key).add(MarcNode.new(model, code, subfield.first.content)) unless subfield.empty?
              end
            end
          end
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

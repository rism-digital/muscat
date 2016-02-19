module Viaf

  class Person
    attr_accessor :name, :dates, :id, :source
  end

  class Search
    attr_accessor :result
    NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
    require 'rexml/document'
    include REXML
    require 'open-uri'

    def self.people(term)
      result = []
      zing = {'ns1'=> "http://www.loc.gov/zing/srw/"}
      cql = "local.mainHeadingEl+all+"
      sort = "&sortKeys=holdingscount"
      recordSchema = "&recordSchema=info:srw/schema/1/marcxml-v1.1"
      max = "&maximumRecords=10"
      x1 = "http://viaf.org/viaf/search?query=#{cql}%22#{URI::encode(term)}%22&httpAccept=application/xml#{sort}#{max}#{recordSchema}"
      doc = Nokogiri::XML(open(x1))
      records = doc.xpath("//ns1:records/ns1:record/ns1:recordData/*", zing)
      records.each do |record|
        p = Person.new
        r = Nokogiri::XML(record.to_xml)
        p.id = r.xpath('//marc:controlfield[@tag="001"]', NAMESPACE)[0].content[4..-1]
        r.xpath('//marc:datafield[@tag="700"]/marc:subfield[@code="a"]', NAMESPACE).each do |n|
          p.name = n.content
          break
        end
        r.xpath('//marc:datafield[@tag="700"]/marc:subfield[@code="d"]', NAMESPACE).each do |n|
          p.dates = n.content
          break
        end
        r.xpath('//marc:datafield[@tag="700"]/marc:subfield[@code="0"]', NAMESPACE).each do |n|
          p.source = n.content
          break
        end
        result << p if p.name
      end
    return result
    end
  end
end

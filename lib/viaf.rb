# This module provides an Interface to the VIAF 

module Viaf

  # A List of VIAF providers sorted by rank

  # This class provides the main search functionality
  class Interface
    NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
    require 'open-uri'
    require 'net/http'

    def self.search(term, model)
      providers = YAML::load(File.open("config/viaf/#{model.to_s.downcase}.yml"))
      result = []
      if model.to_s == 'Person'
        begin 
          query = JSON.load(open(URI.escape("http://viaf.org/viaf/AutoSuggest?query="+term)))
        rescue 
          return "ERROR connecting VIAF AutoSuggest"
        end
      end

      if model.to_s == 'Person'
        if query["result"]
          r = query["result"].map{|e| e if e['nametype']=='personal'}.compact
        else
          return "Sorry, no results were found in VIAF!"
        end
      #this needs another approach because autosuggest is not well supported
      elsif model.to_s == "Work"
        r = []
        uri = URI("http://viaf.org/viaf/search?query=local.uniformTitleWorks=#{URI.escape(term)}&sortKeys=holdingscount&httpAccept=application/json")
        json = Net::HTTP.get(uri)
        res = JSON(json)
        return "Sorry, no work results were found in VIAF!" unless res["searchRetrieveResponse"]["records"]
        res["searchRetrieveResponse"]["records"].each do |record|
          e = {}
          e["viafid"] = record["record"]["recordData"]["viafID"]
          if record["record"]["recordData"]["mainHeadings"]["data"].is_a? Hash
            e["term"] = record["record"]["recordData"]["mainHeadings"]["data"]["text"]
            sources = record["record"]["recordData"]["mainHeadings"]["data"]["sources"]["sid"]
          elsif record["record"]["recordData"]["mainHeadings"]["data"].is_a? Array
            e["term"] = record["record"]["recordData"]["mainHeadings"]["data"][0]["text"]
            sources = record["record"]["recordData"]["mainHeadings"]["data"][0]["sources"]["sid"]
          end
          if sources.is_a? Array
            sources.each do |v|
              e["#{v.split("|").first.downcase}"] = "#{v.split("|").last}"
            end
          elsif sources.is_a? String
            e["#{sources.split("|").first.downcase}"] = "#{sources.split("|").last}"
          end
          r << e
        end
        if res.empty?
          return "Sorry, no work results were found in VIAF!"
        end
      else
        #TODO adopt for other marc classes
        r = query["result"].map{|e| e if e['nametype']=='personal'}.compact
      end
      #ap r
      provider_doc = ""
      r.each do |record|
        providers.keys.each do |provider|
          #puts provider
          if record[provider.downcase]
            provider_id=record[provider.downcase]
          else
            next
          end
          provider_url="http://viaf.org/processed/#{provider}%7C#{URI.escape(provider_id)}?httpAccept=application/xml"
          begin
            links = JSON.load(open(URI.escape("http://viaf.org/viaf/#{record["viafid"]}/justlinks.json")))
          rescue
            return "ERROR connecting VIAF Justlinks"
          end
        
          if !links.is_a?(Hash)
            return "ERROR VIAF Justlinks returned invalid data"
          end
          
          begin
            provider_doc = Nokogiri::XML(open(provider_url))
          rescue 
            return "ERROR connecting VIAF Provider"
          end
          if model.to_s == "Work"
            if provider == "BNF"
              title = build_title_node("240", "440", provider_doc)
              next unless title
            else
              title = build_title_node("100", "400", provider_doc)
              next unless title
            end
          end

          provider_doc.xpath('//marc:controlfield[@tag="001"]', NAMESPACE).first.content = record["viafid"]
          node_24 = provider_doc.xpath('//marc:datafield[@tag="100"]', NAMESPACE)
          provider_doc.xpath('//marc:datafield[@tag="024"]', NAMESPACE).remove
          node_24.first.add_previous_sibling(build_provider_node(provider_doc.root, "VIAF", record["viafid"]))
          node_24.first.add_previous_sibling(build_provider_node(provider_doc.root, provider, provider_id))
          if links["WKP"]
            node_24.first.add_previous_sibling(build_provider_node(provider_doc.root, "WKP", links["WKP"][0]))
          end

          if provider_doc.xpath('//marc:datafield[@tag="100"]', NAMESPACE).empty?
            next
          else
            xslt  = Nokogiri::XSLT(File.read('config/viaf/' + providers[provider]))
            doc = xslt.transform(provider_doc)
            # Escaping for json
            doc = doc.to_s.gsub(/'/, "&apos;").unicode_normalize
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

    def self.build_title_node(tag, alt_tag, provider_doc)
      if tag == "240"
        lastname = provider_doc.xpath("//marc:datafield[@tag='#{tag}']/marc:subfield[@code='a']", NAMESPACE).first.content rescue "Anonymus"
        prename = provider_doc.xpath("//marc:datafield[@tag='#{tag}']/marc:subfield[@code='b']", NAMESPACE).first.content rescue "Anonymus"
        provider_composer = "#{lastname}, #{prename}"
      else
        provider_composer = provider_doc.xpath("//marc:datafield[@tag='#{tag}']/marc:subfield[@code='a']", NAMESPACE).first.content.unicode_normalize rescue "Anonymus"
      end
      #provider_composer = record["term"].split("|").first.gsub([0-9,\-], "")
      composer = Sunspot.search(Person) {fulltext "#{provider_composer}", :fields => [:full_name]}.results.first
      node_100 = provider_doc.xpath("//marc:datafield[@tag='#{tag}']", NAMESPACE)
      return false if node_100.empty?
      sfa = Nokogiri::XML::Node.new "mx:subfield", provider_doc.root
      sfa['code'] = '0'
      sfa.content = composer.id rescue 30004985
      node_100.first << sfa
      nodes_400 = provider_doc.xpath("//marc:datafield[@tag='#{alt_tag}']", NAMESPACE)
      nodes_400.each do |node|
        sfa = Nokogiri::XML::Node.new "mx:subfield", provider_doc.root
        sfa['code'] = '0'
        sfa.content = composer.id rescue 30004985
        node << sfa
      end
      return true
    end

    def self.xsl_test
      xml = File.open("config/viaf/test.xml") { |f| Nokogiri::XML(f)  }
      xslt  = Nokogiri::XSLT(File.read('config/viaf/person_bnf.xsl'))
      doc = xslt.transform(xml)
      puts doc.to_s.split("\n")[0..20].join("\n")
    end

    private_class_method :build_provider_node
  end
end

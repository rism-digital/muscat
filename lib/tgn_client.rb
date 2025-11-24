require 'net/http'
require 'json'

module GettyTGN

  class TGNMetadata
    NS = {
      rdf:  "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
      rdfs: "http://www.w3.org/2000/01/rdf-schema#",
      skos: "http://www.w3.org/2004/02/skos/core#",
      gvp:  "http://vocab.getty.edu/ontology#",
      geo:  "http://www.w3.org/2003/01/geo/wgs84_pos#",
      schema: "http://schema.org/"
    }

    def self.map_parents(parents, place_string)
      values_block = parents.map { |u| "<#{u}>" }.join("\n")

      query = <<~SPARQL
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX gvp: <http://vocab.getty.edu/ontology#>
        PREFIX xl: <http://www.w3.org/2008/05/skos-xl#>

        SELECT ?uri ?prefLabel ?prefLabelLang
        WHERE {
          VALUES ?uri {
            #{values_block}
          }
          ?uri skos:prefLabel ?prefLabel .
          BIND(lang(?prefLabel) AS ?prefLabelLang)
        }
      SPARQL

      client = SPARQL::Client.new("http://vocab.getty.edu/sparql")
      results = client.query(query)

      ordered_labels = place_string.split(",").map(&:strip)

      used_up = []

      ordered = ordered_labels.map do |label|
        row = results.find do |r|
          r[:prefLabel].to_s.casecmp?(label) && used_up.exclude?(r[:uri].to_s)
        end
        next unless row   # skip if missing

        used_up << row[:uri].to_s

        { id: row[:uri].to_s, label: row[:prefLabel].to_s }
      end.compact
      return ordered
    end

    def self.get_metadata_from_xml(xml)
      doc = Nokogiri::XML(xml)
      doc.remove_namespaces! # optional but makes XPath easier

      #puts xml

      subject = doc.at_xpath("//Subject")

      parents_ordered = map_parents(extract_place_type_preferred(subject, doc), extract_parent_string(subject))

      {
        id: extract_id(subject),
        name: extract_pref_label(subject),
        hierarchy_string: extract_parent_string(subject),
        hierarchy: parents_ordered,
        coordinates: extract_coordinates(doc),
      }
    end

    # ---------------------
    # FIELD EXTRACTORS
    # ---------------------

    def self.extract_id(subject)
      subject.at_xpath("./identifier")&.text
    end

    def self.extract_pref_label(subject)
      # Guess what? There can be more than one prefLabel
      # Try to get one that has some text
      subject.xpath('./prefLabel')
          .map(&:text)
          .find { |t| t.strip.present? }
    end

    def self.extract_parent_string(subject)
      subject.at_xpath("./parentString")&.text
    end

    def self.extract_place_type_preferred(subject, doc)
      uri = subject.xpath("//broaderPreferredExtended/@resource", NS).map(&:value)
      return uri
    end

    def self.extract_coordinates(doc)
      lat  = doc.at_xpath("//Place/lat")&.text
      long = doc.at_xpath("//Place/long")&.text
      alt  = doc.at_xpath("//Place/alt")&.text

      return nil unless lat && long

      {
        lat: lat.to_s,
        long: long.to_s,
        alt: alt&.to_s
      }
    end
  end
end

class TgnClient
  BASE_URL = "https://vocab.getty.edu/tgn"
  ENDPOINT = "https://vocab.getty.edu/sparql"

  
  def self.get_tgn(tgn_id)
    url = "https://vocab.getty.edu/tgn/#{tgn_id}.rdf"

    conn = Faraday.new(
      url: url,
      request: { timeout: 10, open_timeout: 5 },
      headers: { "Accept" => "application/rdf+xml", }
    ) do |f|
      f.response :follow_redirects
      f.adapter Faraday.default_adapter
    end

    response = conn.get

    #p response.body

    return GettyTGN::TGNMetadata.get_metadata_from_xml(response.body)

  end

  # This is not nice, but works for now
  def self.brute_parse_tgn(html)
    doc  = Nokogiri::HTML(html)

    rows = []

    # Find the table inside #results
    table = doc.at_css("#results table")

    # Each row is inside many <tbody> tags, each containing a single <tr>
    table.css("tbody tr").each do |tr|
    tds = tr.css("td").map { |td| td.text.strip }

      row_hash = {
        subject:     tds[0],  # e.g. "tgn:7003127"
        term:        tds[1],
        parents:     tds[2],
        description: tds[3],
        type:        tds[4]
      }

      rows << row_hash
    end

    return rows
  end

  def self.search(query)
    url = "https://vocab.getty.edu/resource/getty/search"

    conn = Faraday.new(
      url: url,
      request: { timeout: 10, open_timeout: 5 },
      #headers: { "Accept" => "application/rdf+xml", }
    ) 

    response = conn.get do |req|
      req.params["q"] = query
      req.params["luceneIndex"] = "Brief"
      req.params["indexDataset"] = "TGN"
    end

    raise "Getty lookup failed (#{response.status})" unless response.success?

    return brute_parse_tgn(response.body)

  end

end

class TgnConverter
  def self.to_place_marc(record)
    
    new_marc = MarcPlace.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/place/default.marc")))
    new_marc.load_source false

    new_marc.add_tag_with_subfields("151", a: record[:name])
    new_marc.add_tag_with_subfields("024", a: record[:id], "2": "TGN")

    new_marc.add_tag_with_subfields("034", d: record[:coordinates][:lat],  e: record[:coordinates][:lat], 
                                           f: record[:coordinates][:long],  g: record[:coordinates][:long])

    return new_marc.to_marc.force_encoding("UTF-8")
  end
end
require 'net/http'
require 'json'

module GettyTGN

  class Parser
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

      results.each do |r|
        puts r[:uri]
        puts r[:prefLabel]

      end


      ordered_labels = place_string.split(",").map(&:strip)

      # Build a lookup for speed
      #result_lookup = results.index_by { |r| r[:prefLabel].to_s }

      ordered = ordered_labels.map do |label|
        #row = result_lookup[label]
        row = results.find do |r|
          r[:prefLabel].to_s.downcase.include?(label.downcase)
        end
        next unless row   # skip if missing

        { id: row[:uri].to_s, label: row[:prefLabel].to_s }
      end.compact
      ap ordered
    end

    def self.parse(xml)
      doc = Nokogiri::XML(xml)
      doc.remove_namespaces! # optional but makes XPath easier

      #puts xml

      subject = doc.at_xpath("//Subject")

      map_parents(extract_place_type_preferred(subject, doc), extract_parent_string(subject))

      {
        id: extract_id(subject),
        pref_label: extract_pref_label(subject),
        parent_string: extract_parent_string(subject),
        place_type_preferred: extract_place_type_preferred(subject, doc),
        coordinates: extract_coordinates(doc),
        broader: extract_broader(subject),
      }
    end

    # ---------------------
    # FIELD EXTRACTORS
    # ---------------------

    def self.extract_id(subject)
      subject.at_xpath("./identifier")&.text
    end

    def self.extract_pref_label(subject)
      # skos:prefLabel
      subject.at_xpath('./prefLabel[@xml:lang="en"]')&.text ||
        subject.at_xpath('./prefLabel')&.text
    end

    def self.extract_parent_string(subject)
      subject.at_xpath("./parentString")&.text
    end

    def self.extract_place_type_preferred(subject, doc)
      # gvp:placeTypePreferred → @rdf:resource to AAT URI
      uri = subject.xpath("//broaderPreferredExtended/@resource", NS).map(&:value)

      return uri

    end

    def self.extract_broader(subject)
      subject.xpath("./broader/@rdf:resource", NS).map(&:value)
    end

    def self.extract_coordinates(doc)
      lat  = doc.at_xpath("//Place/lat")&.text
      long = doc.at_xpath("//Place/long")&.text
      alt  = doc.at_xpath("//Place/alt")&.text

      return nil unless lat && long

      {
        lat: lat.to_f,
        long: long.to_f,
        alt: alt&.to_f
      }
    end
  end
end

class TgnClient
  BASE_URL = "https://vocab.getty.edu/tgn"

  ENDPOINT = "https://vocab.getty.edu/sparql"

  def self.parents_for(tgn_id)
    client = SPARQL::Client.new(ENDPOINT)

    query = <<~SPARQL
      PREFIX gvp: <http://vocab.getty.edu/ontology#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX dct: <http://purl.org/dc/elements/1.1/>
      PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

      SELECT DISTINCT ?ancestor ?label ?id (COALESCE(COUNT(?mid), 0) AS ?depth)
      WHERE {
        VALUES ?place { <http://vocab.getty.edu/tgn/#{tgn_id}> }

        # Get all ancestors (unordered)
        ?place gvp:broaderPreferredExtended ?ancestor .

        # Intermediate nodes ancestor -> place for depth calculation
        OPTIONAL { ?ancestor gvp:broaderPreferred+ ?mid . }

        # Metadata
        ?ancestor dct:identifier ?id .
        ?ancestor skos:prefLabel ?label .
        FILTER(LANG(?label) = "en")
      }
      GROUP BY ?ancestor ?label ?id
      ORDER BY ?depth
    SPARQL

    client.query(query).map do |row|
      {
        uri: row[:ancestor].to_s,
        id: row[:id].to_s,
        label: row[:label].to_s,
        depth: row[:depth].to_i
      }
    end
  end

  
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

    ap GettyTGN::Parser.parse(response.body)

  end

  # This is not nice, but works for now
  def self.brute_parse_tng(html)
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
ap response
    raise "Getty lookup failed (#{response.status})" unless response.success?

    ap brute_parse_tng(response.body)

  end

end
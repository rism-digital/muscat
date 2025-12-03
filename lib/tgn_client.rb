require 'net/http'
require 'json'

module GettyTGN


THE_STATIC_MAP = {
    "tgn:1000061" => "XA-AD",
    "tgn:7006417" => "XA-AL",
    "tgn:1000062" => "XA-AT",
    "tgn:7006664" => "XA-BA",
    "tgn:1000063" => "XA-NL",
    "tgn:7006413" => "XA-BG",
    "tgn:7006657" => "XA-BY",
    "tgn:7011731" => "XA-CH",
    "tgn:1001780" => "XA-CZ",
    "tgn:7000084" => "XA-DE",
    "tgn:1000066" => "XA-DK",
    "tgn:7006540" => "XA-EE",
    "tgn:1000095" => "XA-ES",
    "tgn:1000069" => "XA-FI",
    "tgn:1000070" => "XA-FR",
    "tgn:1000172" => "XA-GB",
    "tgn:7008591" => "XA-GB-NIR",
    "tgn:1000074" => "XA-GR",
    "tgn:7006663" => "XA-HR",
    "tgn:7006278" => "XA-HU",
    "tgn:1000078" => "XA-IE",
    "tgn:1000077" => "XA-IS",
    "tgn:1000080" => "XA-IT",
    "tgn:7003515" => "XA-LI",
    "tgn:7006542" => "XA-LT",
    "tgn:7003514" => "XA-LU",
    "tgn:7006541" => "XA-LV",
    "tgn:7005758" => "XA-MC",
    "tgn:7006656" => "XA-MD",
    "tgn:7015657" => "XA-ME",
    "tgn:7006667" => "XA-MK",
    "tgn:7005729" => "XA-MT",
    "tgn:1000088" => "XA-NO",
    "tgn:7006366" => "XA-PL",
    "tgn:1000090" => "XA-PT",
    "tgn:1000091" => "XA-RO",
    "tgn:7006669" => "XA-RS",
    "tgn:7002435" => "XA-RU",
    "tgn:7006670" => "XA-SI",
    "tgn:7011765" => "XA-SK",
    "tgn:7005699" => "XA-SM",
    "tgn:1000097" => "XA-SE",
    "tgn:7006660" => "XA-UA",
    "tgn:7001168" => "XA-VA",
    "tgn:7006651" => "XB-AM",
    "tgn:7006646" => "XB-AZ",
    "tgn:1000105" => "XB-PK",
    "tgn:1000141" => "XB-TW",
    "tgn:7006653" => "XB-GE",
    "tgn:1000116" => "XB-ID",
    "tgn:1000119" => "XB-IL",
    "tgn:7000198" => "XB-IN",
    "tgn:1000118" => "XB-IQ",
    "tgn:7000231" => "XB-IR",
    "tgn:1000120" => "XB-JP",
    "tgn:1000109" => "XB-KH",
    "tgn:7000299" => "XB-KR",
    "tgn:1000126" => "XB-LB",
    "tgn:1000135" => "XB-PH",
    "tgn:1000137" => "XB-SA",
    "tgn:1000140" => "XB-SY",
    "tgn:7014835" => "XB-TJ",
    "tgn:7006659" => "XB-TM",
    "tgn:1000144" => "XB-TR",
    "tgn:7006661" => "XB-UZ",
    "tgn:1000145" => "XB-VN",
    "tgn:7016752" => "XC-DZ",
    "tgn:1000201" => "XC-EG",
    "tgn:1000166" => "XC-GH",
    "tgn:7006160" => "XE-PG",
    "tgn:1000205" => "XC-TN",
    "tgn:1000206" => "XC-UG",
    "tgn:1000198" => "XC-ZA",
    "tgn:7006477" => "XD-AR",
    "tgn:1000046" => "XD-BO",
    "tgn:1000047" => "XD-BR",
    "tgn:7005685" => "XD-CA",
    "tgn:1000049" => "XD-CL",
    "tgn:1000050" => "XD-CO",
    "tgn:7005364" => "XD-CR",
    "tgn:7004624" => "XD-CU",
    "tgn:1000051" => "XD-EC",
    "tgn:7005493" => "XD-GT",
    "tgn:7005346" => "XD-HN",
    "tgn:7005556" => "XD-JM",
    "tgn:7005560" => "XD-MX",
    "tgn:7005562" => "XD-NI",
    "tgn:1000056" => "XD-PE",
    "tgn:1000055" => "XD-PY",
    "tgn:7015386" => "XD-SR",
    "tgn:1000143" => "XD-US",
    "tgn:1000058" => "XD-UY",
    "tgn:1000059" => "XD-VE",
    "tgn:7000490" => "XE-AU",
    "tgn:1000226" => "XE-NZ",
    "tgn:7004543" => "XB-HK",
    "tgn:7004643" => "XD-PR",
    "tgn:7004787" => "XD-TT"
  }

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

    def self.get_hierarchy(id)
      query = <<~SPARQL
        PREFIX gvp: <http://vocab.getty.edu/ontology#>
        PREFIX xl:  <http://www.w3.org/2008/05/skos-xl#>
        PREFIX tgn: <http://vocab.getty.edu/tgn/>

        SELECT ?place ?placeLabel ?placeType
              ?ancestor ?ancestorLabel ?ancestorType
              (MIN(?d) AS ?level)
        WHERE {
          VALUES ?place { tgn:#{id} } # Little Marton

          # Place label/type
          ?place gvp:prefLabelGVP/xl:literalForm ?placeLabel .
          ?place gvp:placeTypePreferred/gvp:prefLabelGVP/xl:literalForm ?placeType .

          # Any ancestor including self (0 steps)
          ?place gvp:broaderPreferred* ?ancestor .

          # Ancestor label/type
          #?ancestor gvp:prefLabelGVP/xl:literalForm ?ancestorLabel .
          ?ancestor gvp:placeTypePreferred/gvp:prefLabelGVP/xl:literalForm ?ancestorType .

          # Try to get the English label
          # Or any other label
          OPTIONAL {
            ?ancestor skos:prefLabel ?labelEn .
            FILTER(LANGMATCHES(LANG(?labelEn), "en"))
          }

          OPTIONAL {
            SELECT ?ancestor ?labelNonEn
            WHERE {
              ?ancestor skos:prefLabel ?labelNonEn .
              FILTER(!LANGMATCHES(LANG(?labelNonEn), "en"))
            }
            ORDER BY (IF(LANG(?labelNonEn) = "", 0, 1)) LCASE(STR(?labelNonEn))
            LIMIT 1
          }

        BIND(COALESCE(?labelEn, ?labelNonEn) AS ?ancestorLabel)

          # Compute distance (# of broaderPreferred hops) to ancestor
          {
            SELECT ?place ?ancestor (COUNT(?mid) AS ?d)
            WHERE {
              VALUES ?place { tgn:#{id} }
              ?place gvp:broaderPreferred* ?ancestor .
              OPTIONAL {
                ?place gvp:broaderPreferred+ ?mid .
                ?mid   gvp:broaderPreferred* ?ancestor .
              }
            }
            GROUP BY ?place ?ancestor
          }
        }
        GROUP BY ?place ?placeLabel ?placeType ?ancestor ?ancestorLabel ?ancestorType
        ORDER BY ?level
      SPARQL

      client = SPARQL::Client.new("http://vocab.getty.edu/sparql")
      results = client.query(query)

      return results.map do |r|
        next if r[:level] == 0 # Skip ourselves

        {
          id: r[:ancestor]&.to_s,
          label: r[:ancestorLabel]&.to_s,
          type: r[:ancestorType]&.to_s
        }
      end
    end

    def self.get_metadata_from_xml(xml)
      doc = Nokogiri::XML(xml)
      doc.remove_namespaces! # optional but makes XPath easier

      subject = doc.at_xpath("//Subject")
      id = extract_id(subject)

      #parents_ordered = map_parents(extract_place_type_preferred(subject, doc), extract_parent_string(subject))
      parents_ordered = get_hierarchy(id)
      # try to het the nation

      country = THE_STATIC_MAP.map {|k,v|
        full_id = k.sub("tgn:", "http://vocab.getty.edu/tgn/")
        {k => v} if parents_ordered.any? { |h| h[:id] == full_id }
      }.compact&.first

      {
        id: extract_id(subject),
        name: extract_pref_label(subject),
        hierarchy_string: extract_parent_string(subject),
        hierarchy: parents_ordered,
        coordinates: extract_coordinates(doc),
        country: country
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
      req.params["limit"] = 300
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

    if record[:country] != nil
      new_marc.add_tag_with_subfields("043", "2": "rismg", c: record[:country].values.first)
      new_marc.add_tag_with_subfields("043", "2": "TGN", b: record[:country].keys.first)
    end

    record[:hierarchy].each do |item|
      new_marc.add_tag_with_subfields("370", "4": "TGN", c: item[:id], f: item[:label])
    end



    return new_marc.to_marc.force_encoding("UTF-8")
  end
end
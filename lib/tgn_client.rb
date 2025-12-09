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
end

class TgnClient

  def self.pull_from_tgn(id)
    query = <<~SPARQL
      PREFIX gvp: <http://vocab.getty.edu/ontology#>
      PREFIX xl:  <http://www.w3.org/2008/05/skos-xl#>
      PREFIX tgn: <http://vocab.getty.edu/tgn/>

      SELECT ?place ?placeLabel ?placeType ?placeLabelsAll
            ?ancestor ?ancestorLabel ?ancestorType ?lat ?long
            (MIN(?d) AS ?level)
      WHERE {
        VALUES ?place { tgn:#{id} }

        # Place label/type
        #?place gvp:prefLabelGVP/xl:literalForm ?placeLabel .
        ?place gvp:placeTypePreferred/gvp:prefLabelGVP/xl:literalForm ?placeType .

        # Get some info on the original place
        OPTIONAL { ?place foaf:focus/wgs:lat  ?lat . }
        OPTIONAL { ?place foaf:focus/wgs:long ?long . }

        # Try to get a working label for this place
        OPTIONAL {
          ?place skos:prefLabel ?placeLabelEn .
          FILTER(LANGMATCHES(LANG(?placeLabelEn), "en"))
        }

        OPTIONAL {
          SELECT ?place ?placeLabelNonEn
          WHERE {
            ?place skos:prefLabel ?placeLabelNonEn .
            FILTER(!LANGMATCHES(LANG(?placeLabelNonEn), "en"))
          }
          ORDER BY (IF(LANG(?placeLabelNonEn) = "", 0, 1)) LCASE(STR(?placeLabelNonEn))
          LIMIT 1
        }

        BIND(COALESCE(?placeLabelEn, ?placeLabelNonEn) AS ?placeLabel)

OPTIONAL {
  SELECT ?place (GROUP_CONCAT(DISTINCT STR(?l); separator=" | ") AS ?placeLabelsAll)
  WHERE {
    VALUES ?place { tgn:#{id} }
    ?place rdfs:label ?l .
  }
  GROUP BY ?place
}

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
      GROUP BY ?place ?placeLabel ?placeType ?ancestor ?ancestorLabel ?ancestorType ?lat ?long ?placeLabelsAll
      ORDER BY ?level
    SPARQL

    client = SPARQL::Client.new("http://vocab.getty.edu/sparql")
    results = client.query(query)

    # mmmmmmh?
    return nil if results[0].count == 0

    parents_ordered = results.map do |r|
      next if r[:level]&.to_i == 0 # Skip ourselves

      # Skip "World"
      next if r[:ancestor].to_s == "http://vocab.getty.edu/tgn/7029392"

      {
        id: r[:ancestor]&.to_s,
        label: r[:ancestorLabel]&.to_s,
        type: r[:ancestorType]&.to_s
      }
    end.compact

    place = results[0] # this is uss

    country = GettyTGN::THE_STATIC_MAP.map {|k,v|
      full_id = k.sub("tgn:", "http://vocab.getty.edu/tgn/")
      {k => v} if parents_ordered.any? { |h| h[:id] == full_id }
    }.compact&.first

    alt_labels = []
    if place[:placeLabelsAll]&.to_s
      alt_labels = place[:placeLabelsAll].to_s.split(/\s*\|\s*/).map(&:strip).reject(&:empty?).reject { |v| v == place[:placeLabel]&.to_s }
    end

    {
      id: id,
      name: place[:placeLabel]&.to_s,
      place_lang: place[:placeLabel]&.language,
      hierarchy: parents_ordered,
      coordinates: {lat: place[:lat]&.to_s, long: place[:long]&.to_s},
      country: country,
      alternate_names: alt_labels
    }

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

      # Skip stuff like Canyon and railway stations
      next if !tds[4].include?("inhabited places")

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

    #raise "Getty lookup failed (#{response.status})" unless response.success?

    return brute_parse_tgn(response.body)

  end

end

class TgnConverter
  def self.to_place_marc(record, new_marc = nil)
    
    if !new_marc
      new_marc = MarcPlace.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/place/default.marc")))
      new_marc.load_source false
    end

    # Purge all the old values
    new_marc.by_tags("151").each {|t2| t2.destroy_yourself}

    # Try to match the language in which the item comes
    lang = Iso639[record[:place_lang]]&.alpha3_bibliographic

    new_marc.add_tag_with_subfields("151", a: record[:name], g: lang)
    new_marc.add_tag_with_subfields("024", a: record[:id], "2": "TGN")

    new_marc.add_tag_with_subfields("034", d: record[:coordinates][:lat],  e: record[:coordinates][:lat], 
                                           f: record[:coordinates][:long],  g: record[:coordinates][:long])

    if record[:country] != nil
      new_marc.add_tag_with_subfields("043", "2": "rismg", c: record[:country].values.first)
      # Country id, do we need this?
      #new_marc.add_tag_with_subfields("043", "2": "TGN", b: record[:country].keys.first)
    end

    # Purge the legacy district and country
    new_marc.by_tags("970").each {|t2| t2.destroy_yourself}

    legacy_country = ""
    legacy_district = ""

    record[:hierarchy].each do |item|
      new_marc.add_tag_with_subfields("370", "4": item[:type], c: item[:id], f: item[:label])
      # Save the coutry
      legacy_country = item[:label] if item[:type] == "nations"
      legacy_district = item[:label] if item[:type] == "provinces" || item[:type].include?("regions")
    end

    if !legacy_country.empty? || legacy_district.empty
      new_marc.add_tag_with_subfields("970", a: legacy_country, c: legacy_district)
    end

    record[:alternate_names].each do |alt|
      new_marc.add_tag_with_subfields("451", a: alt)
    end

    return new_marc.to_marc.force_encoding("UTF-8")
  end
end
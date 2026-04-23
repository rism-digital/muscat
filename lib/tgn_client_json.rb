# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

class TgnClientJson
  DEFAULT_BASE_URL = "https://tgn-mirror.rism.online".freeze

  class Error < StandardError; end
  class RequestError < Error; end
  class ParseError < Error; end

  attr_reader :base_url, :open_timeout, :read_timeout

  def initialize(base_url: DEFAULT_BASE_URL, open_timeout: 5, read_timeout: 15)
    @base_url = base_url.sub(%r{/\z}, "")
    @open_timeout = open_timeout
    @read_timeout = read_timeout
  end

  # Fetch raw JSON for a place id
  #
  # adapter.fetch_place_json(1004257)
  # => { ...parsed JSON hash... }
  def fetch_place_json(place_id)
    response = get("/places/#{place_id}")
    parse_json(response.body, place_id: place_id)
  end

  # Fetch and normalize a place into a Ruby hash
  #
  # adapter.fetch_place(1004257)
  # => {
  #      id: 1004257,
  #      label: "...",
  #      raw: {...}
  #    }
  def fetch_marc_place(place_id, marc = nil)
    raw = fetch_place_json(place_id)
    place2marc(raw, marc)
  end

  private

  def get(path)
    uri = URI.parse("#{base_url}#{path}")

    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/json"
    request.basic_auth(Rails.application.credentials.tgn.user, Rails.application.credentials.tgn.password)

    Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: open_timeout,
      read_timeout: read_timeout
    ) do |http|
      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise RequestError, "GET #{uri} failed: #{response.code} #{response.message}"
      end

      response
    end
  rescue Timeout::Error, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
    raise RequestError, "GET #{uri} failed: #{e.class} #{e.message}"
  end

  def parse_json(body, place_id:)
    JSON.parse(body)
  rescue JSON::ParserError => e
    raise ParseError, "Invalid JSON for place #{place_id}: #{e.message}"
  end


  def place2marc(record, new_marc = nil)
    if !new_marc
      new_marc = MarcPlace.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/place/default.marc")))
      new_marc.load_source false
    end

    # Purge all the old values
    new_marc.by_tags("151").each {|t2| t2.destroy_yourself}
    new_marc.by_tags("034").each {|t2| t2.destroy_yourself}
    new_marc.by_tags("370").each {|t2| t2.destroy_yourself}

    # Try to match the language in which the item comes
    lang = Iso639[record[:place_lang]]&.alpha3_bibliographic

    new_marc.add_tag_with_subfields("151", a: record["preferred_term"], g: lang)
    # 024 should not be there
    new_marc.add_tag_with_subfields("024", a: record["tgn_id"], "2": "TGN")

    new_marc.add_tag_with_subfields("034", d: record["lon"],  e: record["lon"], 
                                           f: record["lat"],  g: record["lat"])

    ## We decided to remove 043
    #if record[:country] != nil
    #  new_marc.add_tag_with_subfields("043", "2": "rismg", c: record[:country].values.first)
    #end

    #
    #new_marc.add_tag_with_subfields("075", a: record["place_type_label"], b: record[:type_code])

    # Purge the legacy district and country
    new_marc.by_tags("970").each {|t2| t2.destroy_yourself}

=begin
The $c is for the country so the current practice of storing the place type URI is not correct. This should only be filled out with a value of a "nation" record (since that is what Getty calls a sovereign state; it calls "England" a country, but we don't want that.)

The $f is for the place name if it is not a country.

$2 should be `tgn` if it comes from TGN.

$u should be the URL to the record in Getty

$i should be the relationship name (e.g., "inhabited places"); $4 should be the AAT URI for the place type
        [2] [
            [0] 7008136,
            [1] "Greater London",
            [2] 83061,
            [3] "metropolitan area"
        ],
=end


    record["ancestor_pairs"].each do |id, label, aid, type|
      c = type == "nation" ? label : nil
      f = type != "nation" ? label : nil
      new_marc.add_tag_with_subfields("370", "2": "tgn", c: c, f: f, i: type, u: "https://vocab.getty.edu/tgn/#{id}")
    end

    # Alt names
=begin
    existing = new_marc["451"].flat_map { |t| Array(t["a"]) }
      .map { |tt| tt&.content.to_s.strip.downcase }
      .compact
      .to_set

    record[:alternate_names].each do |alt|
      norm = alt.to_s.strip.downcase
      next if existing.include?(norm)

      new_marc.add_tag_with_subfields("451", a: alt)
      existing.add(norm) # Make sure we don't add dups
    end
=end 
    return new_marc
  end



  
end
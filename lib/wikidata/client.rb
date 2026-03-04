# app/services/wikidata/client.rb
# Minimal client for Wikidata Wikibase REST API.
#
# Usage:
#   Wikidata::Client.new.get_item("Q1387014")

require "json"
require "net/http"
require "uri"

module Wikidata
  class Client
    class ItemNotFound < StandardError; end
    class InvalidQid < StandardError; end
    class ConnectionError < StandardError; end

    BASE_URL  = "https://www.wikidata.org/w/rest.php/wikibase/v1/entities/items".freeze
    USER_AGENT = "rism-digital (info@rism.digital)".freeze

    def initialize(timeout: 10, open_timeout: 5)
      @timeout = timeout
      @open_timeout = open_timeout
    end

    # Fetch raw item JSON (Ruby Hash) for a Q-id.
    def get_item(qid)
      validate_qid!(qid)

      uri = URI("#{BASE_URL}/#{qid}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = @open_timeout
      http.read_timeout = @timeout

      req = Net::HTTP::Get.new(uri)
      req["Accept"] = "application/json"
      req["User-Agent"] = USER_AGENT

      res = http.request(req)

      if res.is_a?(Net::HTTPNotFound)
        raise ItemNotFound, qid
      end

      unless res.is_a?(Net::HTTPSuccess)
        raise ConnectionError, "HTTP #{res.code} #{res.message} (#{qid})"
      end

      JSON.parse(res.body)
    end

    private

    def validate_qid!(qid)
      raise InvalidQid, qid unless qid.to_s.match?(/\AQ\d+\z/)
    end
  end
end
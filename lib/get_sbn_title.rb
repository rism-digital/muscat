# frozen_string_literal: true

require "cgi"
require "json"
require "net/http"
require "uri"

module GetSBNTitle
  ENDPOINT = "https://opac.sbn.it/o/opac-api/title"

  def self.call(id)
    uri = URI(ENDPOINT)
    uri.query = URI.encode_www_form(id: id, core: "opere")

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 15) do |http|
      http.get(uri.request_uri)
    end
    raise "SBN request failed: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    title = JSON.parse(response.body).dig("data", "results", 0, "title")
    title && CGI.unescapeHTML(title).strip
  end
end

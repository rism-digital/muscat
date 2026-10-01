module TgnPlaceShowHelper
  TGN_URL_PATTERN = %r{\Ahttps?://vocab\.getty\.edu/tgn/(\d+)/?\z}i.freeze

  def associated_place_tgn_id(tag)
    return unless tag.tag == "370"

    authority = tag.fetch_first_by_tag("2")&.content.to_s
    return unless authority.casecmp?("tgn")

    url = tag.fetch_first_by_tag("u")&.content.to_s.strip
    TGN_URL_PATTERN.match(url)&.[](1)
  end
end

# app/lib/identifier_link.rb
module IdentifierLink
  URL_BUILDERS = {
    "BNF"   => ->(id) { "http://ark.bnf.fr/#{id}" },
    "DNB"   => ->(id) { "http://d-nb.info/gnd/#{id}" },
    "MBZ"   => ->(id) { "https://musicbrainz.org/work/#{id}" },
    "VIAF"  => ->(id) { "http://viaf.org/viaf/#{id}" },
    "ICCU"  => ->(id) { "http://id.sbn.it/bid/#{id}" },
    "WKP"   => ->(id) { "https://www.wikidata.org/wiki/#{id}" },
    "BNE"   => ->(id) { "https://datos.bne.es/entidad/#{id}" },
    "ISNI"  => ->(id) { "https://isni.org/isni/#{id}" },
    "LC"    => ->(id) { "https://lccn.loc.gov/#{id}" },
    "ORCID" => ->(id) { "https://orcid.org/#{id}" },
    "NLP"   => ->(id) { "https://dbn.bn.org.pl/descriptor-details/#{id}" },
    "OCLC"  => ->(id) { "https://entities.oclc.org/worldcat/entity/#{id}" },
    "CMO"   => ->(id) { "https://corpus-musicae-ottomanicae.de/receive/#{id}" }
  }.freeze

  def self.generate_url(identifier, id)
    return nil if identifier.blank? || id.blank?

    builder = URL_BUILDERS[identifier.to_s.strip.upcase]
    builder&.call(id.to_s.strip)
  end

  def self.linkable?(identifier)
    URL_BUILDERS.key?(identifier.to_s.strip.upcase)
  end
end
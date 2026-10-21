# Print Swiss publishers and printers as TSV.
#
# The 043 country code is too incomplete for this report, so candidates are
# selected by comparing 110 $c text with Swiss Place names and the embedded
# fallback list below. There do not need to be database links between the
# Institution and Place records.

swiss_places = <<~PLACES.lines(chomp: true).reject(&:empty?)
  Aarau
  Adliswil
  Aesch
  Affoltern am Albis
  Aigle
  Allschwil
  Altdorf
  Altstätten
  Amriswil
  Andermatt
  Appenzell
  Arbon
  Arlesheim
  Arosa
  Ascona
  Baar
  Baden AG
  Bad Ragaz
  Balsthal
  Ballwil
  Basel
  Bellinzona
  Belp
  Bern
  Berne
  Beromünster
  Bettingen
  Bex
  Biel
  Biel/Bienne
  Bienne
  Binningen
  Bischofszell
  Brig
  Brigue
  Brugg
  Buchs AG
  Buchs SG
  Bulle
  Burgdorf
  Carouge
  Celerina
  Celerina/Schlarigna
  Cham
  Chiasso
  Chur
  Coira
  Couvet
  Davos
  Delémont
  Disentis
  Disentis/Mustér
  Dornach
  Dübendorf
  Einsiedeln
  Emmen
  Emmishofen
  Engelberg
  Estavayer-le-Lac
  Frauenfeld
  Freiburg i. Üe.
  Fribourg
  Genève
  Geneva
  Glarus
  Gossau
  Grenchen
  Gruyères
  Gümmenen
  Herisau
  Horgen
  Heiden
  Hochdorf
  Huttwil
  Ilanz
  Ilanz / Glion
  Interlaken
  Kirchberg (Sankt Gallen)
  Küsnacht
  Kreuzlingen
  La Chaux-de-Fonds
  Langenthal
  Langnau
  Langnau im Emmental
  Lausanne
  Lenzburg
  Liestal
  Locarno
  Lugano
  Luzern
  Lucerne
  Martigny
  Mendrisio
  Montreux
  Morges
  Moutier
  Murten
  Morat
  Neuchâtel
  Neuhausen am Rheinfall
  Nyon
  Olten
  Payerne
  Porrentruy
  Poschiavo
  Rapperswil
  Rapperswil-Jona
  Rathausen
  Reinach
  Rheinfelden AG
  Rorschach
  Saanen
  Sachseln
  Samedan
  Sarnen
  Schaffhausen
  Schlarigna
  Schwyz
  Scuol
  Sierre
  Sion
  Soglio
  Solothurn
  St. Gallen
  Sankt Gallen
  Stans
  Stein am Rhein
  Strada
  Sursee
  Thun
  Trogen
  Tschlin
  Uster
  Uzwil
  Vevey
  Visp
  Wattenwil
  Weggis
  Wettingen
  Wetzikon
  Wiesendangen
  Wil
  Winterthur
  Yverdon
  Yverdon-les-Bains
  Zell
  Zernez
  Zofingen
  Zollikon
  Zug
  Zuzgen
  Zürich
  Zurich
PLACES

swiss_country_names = [
  "Schweiz",
  "Suisse",
  "Svizzera",
  "Suisse/Schweiz",
  "Switzerland"
].freeze

# Extend the fallback list with current Place names and their alternate terms.
# This is deliberately a textual lookup: Institution 110 $c has no Place link.
Place.where(country: swiss_country_names).pluck(:name, :alternate_terms).each do |name, alternate_terms|
  swiss_places << name if name.present?
  swiss_places.concat(alternate_terms.to_s.lines(chomp: true).reject(&:empty?))
end

normalize = lambda do |value|
  I18n.transliterate(value.to_s)
      .downcase
      .gsub(/[[:space:]]+/, " ")
      .strip
end

swiss_place_names = swiss_places.map { |place| normalize.call(place) }.to_set.freeze
roles_to_find = %w[Publisher Printer].freeze

marc_values = lambda do |institution, tag, subfield|
  institution.marc[tag].flat_map do |field|
    field[subfield].filter_map do |value|
      content = value.content.to_s.strip
      content unless content.empty?
    end
  end
end

tsv_value = lambda do |value|
  value.to_s.gsub(/[\t\r\n]+/, " ").strip
end

puts ["id", "110$a", "110$c", "368$a", "551$a"].join("\t")

Institution.find_each(batch_size: 500) do |institution|
  roles = marc_values.call(institution, "368", "a") & roles_to_find
  next if roles.empty?

  corporate_names = marc_values.call(institution, "110", "a")
  corporate_places = marc_values.call(institution, "110", "c")

  # A 110 $c may contain several places separated by semicolons. "et al."
  # occurs in a few legacy records and does not form part of the place name.
  place_parts = corporate_places.flat_map { |value| value.split(";") }
                                .map { |value| value.sub(/\s+et al\.\z/i, "") }
                                .map { |value| normalize.call(value) }

  next unless place_parts.any? { |place| swiss_place_names.include?(place) }

  activity_places = marc_values.call(institution, "551", "a")

  puts [
    institution.id,
    corporate_names.join(" | "),
    corporate_places.join(" | "),
    roles.join(" | "),
    activity_places.join(" | ")
  ].map { |value| tsv_value.call(value) }.join("\t")
end

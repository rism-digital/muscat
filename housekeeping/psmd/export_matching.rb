require "csv"
require_relative "legacy_file"

input_path = File.join(__dir__, "mapping_sept_26.tsv")
output_path = ARGV.fetch(0, File.join(__dir__, "matching.csv"))
legacy = LegacyFile.new(File.join(__dir__, "psmd.yml"))

headers = [
  "Muscat 001",
  "Muscat 240$a",
  "Muscat 245$a",
  "Muscat 730$a",
  "Muscat 650$a",
  "PSMD link",
  "PSMD 240$a",
  "PSMD 245$a",
  "PSMD 730$a",
  "PSMD child record count"
]

def subfield_values(marc, tag, subfield)
  return [] unless marc

  marc[tag].flat_map do |field|
    field[subfield].map { |value| value.content.to_s.strip }
  end.reject(&:empty?)
end

def joined_subfield_values(marc, tag, subfield)
  subfield_values(marc, tag, subfield).join(" | ")
end

CSV.open(output_path, "w", headers: headers, write_headers: true) do |output|
  CSV.foreach(input_path, col_sep: "\t") do |row|
    psmd_id = row[0].to_s.strip
    muscat_id = row[1].to_s.strip

    source = Source.find_by_id(muscat_id)
    warn "Muscat source not found: #{muscat_id}" unless source
    muscat_marc = source&.marc
    muscat_marc&.load_source(false)

    manuscript = legacy.find_by(:manuscripts, :ext_id, psmd_id)
    warn "PSMD manuscript not found: #{psmd_id}" unless manuscript
    psmd_marc = manuscript && MarcGndWork.new(manuscript["source"])
    psmd_marc&.load_source(false)

    child_count = if psmd_marc
      psmd_marc["600"].count { |field| field["0"].first&.content }
    end

    output << [
      muscat_marc&.get_marc_source_id,
      joined_subfield_values(muscat_marc, "240", "a"),
      joined_subfield_values(muscat_marc, "245", "a"),
      joined_subfield_values(muscat_marc, "730", "a"),
      joined_subfield_values(muscat_marc, "650", "a"),
      "http://printed-sacred-music.org/manuscripts/#{psmd_id}",
      joined_subfield_values(psmd_marc, "240", "a"),
      joined_subfield_values(psmd_marc, "245", "a"),
      joined_subfield_values(psmd_marc, "730", "a"),
      child_count
    ]
  end
end

puts "Wrote #{output_path}"

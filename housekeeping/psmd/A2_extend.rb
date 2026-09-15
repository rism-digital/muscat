require_relative 'psmd_conversion.rb'

copy_map = [
  {
    from: "005",
    to: "599",
    subfields: { "a" => "a" }
  },
  {
    from: "040",
    to: "040",
    subfields: { "b" => "b" }
  },

  {
    from: "240",
    to: "730",
    subfields: {"a" => "a" }
  },
  {
    from: "245",
    to: "245",
    subfields: {"a" => "a" }
  }, 

  {
    from: "260",
    to: "260",
    subfields: {"a" => "a", "b" => "b", "c" => "c", "e" => "e", "f" => "f" }
  }, 
  {
    from: "300",
    to: "300",
    subfields: {"a" => "a", "b" => "b", "c" => "c" }
  }, 
  {
    from: "340",
    to: "340",
    subfields: {"d" => "d" }
  },
  {
    from: "500",
    to: "500",
    subfields: {"d" => "d" }
  }, 
  {
    from: "505",
    to: "505",
    subfields: {"a" => "a" }
  }, 

  {
    from: "599",
    to: "599",
    subfields: {"a" => "a" }
  }, 
  {
    from: "650",
    to: "650",
    subfields: {"a" => "a" }
  }, 
  {
    from: "690",
    to: "690",
    subfields: {"a" => "a", "n" => "n", "0" => "0" },
    map: PsmdConversion.publication_map
  }, 
  {
    from: "691",
    to: "691",
    subfields: { "a" => "a", "n" => "n", "0" => "0" },
    map: PsmdConversion.publication_map
  },

]

CSV.parse(File.read("housekeeping/psmd/enhance_list.tsv"), col_sep: "\t", headers: %i[psmd_id muscat_id]).each do |r|

  ms = PsmdConversion.legacy.find(:manuscripts, r[:psmd_id])

  # GndWork loads ALL numbers as marc tags
  old = MarcGndWork.new(ms["source"])
  old.load_source false

  source = Source.find(r[:muscat_id])

  PsmdConversion.copy_from_source_marc(old, source.marc, copy_map)

  source.marc.add_tag_with_subfields("599", a: "Imported from PSMD manuscripts/#{ms["ext_id"]} (#{ms["id"]})")
  source.marc.add_tag_with_subfields("691", "0": 50006603, u: "http://printed-sacred-music.org/manuscripts/#{ms["ext_id"]}")

  source.save
  puts "PSMD #{r[:psmd_id]} to #{source.id}"
  
  PsmdConversion.create_holding_records(source, old, ms)

  if source.child_sources.count == 0
    PsmdConversion.migrate_child_records(source, old, ms)
  end

end
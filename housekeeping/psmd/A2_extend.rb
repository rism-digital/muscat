require_relative 'psmd_conversion.rb'

copy_map = [
  {
    from: "005",
    to: "599",
    subfields: { "a" => "a" }
  },
  #{
  #  from: "040",
  #  to: "040",
  #  subfields: { "b" => "b" }
  #},

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

child_folder = Folder.new(:name => "PSMD Child records " + DateTime.now.to_s, :folder_type => "Source", wf_owner: PsmdConversion::USER_ID)
child_folder.save

holding_folder = Folder.new(:name => "PSMD Holding records " + DateTime.now.to_s, :folder_type => "Holding", wf_owner: PsmdConversion::USER_ID)
holding_folder.save

modified_sources = Folder.new(:name => "PSMD Extended sources " + DateTime.now.to_s, :folder_type => "Source", wf_owner: PsmdConversion::USER_ID)
modified_sources.save

CSV.parse(File.read("housekeeping/psmd/enhance_list.tsv"), col_sep: "\t", headers: %i[psmd_id muscat_id]).each do |r|

  ms = PsmdConversion.legacy.find(:manuscripts, r[:psmd_id])

  # GndWork loads ALL numbers as marc tags
  old = MarcGndWork.new(ms["source"])
  old.load_source false

  source = Source.find(r[:muscat_id])

  PsmdConversion.copy_from_source_marc(old, source.marc, copy_map)

  source.marc.add_tag_with_subfields("599", a: "Merged from PSMD manuscripts/#{ms["ext_id"]} (internal id #{ms["id"]})")
  #source.marc.add_tag_with_subfields("691", "0": 50006603, u: "http://printed-sacred-music.org/manuscripts/#{ms["ext_id"]}")
  source.marc.add_tag_with_subfields("910", "0": 51009572)

  source.save
  source.reindex
  puts "PSMD #{r[:psmd_id]} to #{source.id}"

  PsmdConversion.attach_508_markdown(old, source, ms["ext_id"])

  modified_sources.add_item(source)
  
  PsmdConversion.create_holding_records(source, old, ms, holding_folder)

  if source.child_sources.count == 0
    PsmdConversion.migrate_child_records(source, old, ms, child_folder)
  end

  # MAke the GC happy? I guess?
  source = nil

end

# Removed
# 2493	990048328

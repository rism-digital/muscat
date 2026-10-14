require_relative 'psmd_conversion.rb'
PsmdConversion.start_logging("A2_extend")

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
child_folder_saved = child_folder.save
PsmdConversion.log_persistence_error(child_folder) unless child_folder_saved

holding_folder = Folder.new(:name => "PSMD Holding records " + DateTime.now.to_s, :folder_type => "Holding", wf_owner: PsmdConversion::USER_ID)
holding_folder_saved = holding_folder.save
PsmdConversion.log_persistence_error(holding_folder) unless holding_folder_saved

modified_sources = Folder.new(:name => "PSMD Extended sources " + DateTime.now.to_s, :folder_type => "Source", wf_owner: PsmdConversion::USER_ID)
modified_sources_saved = modified_sources.save
PsmdConversion.log_persistence_error(modified_sources) unless modified_sources_saved

consulted_sigla_by_source_id = Hash.new { |hash, key| hash[key] = [] }
CSV.foreach(File.join(__dir__, "copy_consulted_enhance.csv")) do |row|
  muscat_id = row[0].to_s.split("/").last
  consulted_sigla_by_source_id[muscat_id].concat(row[1].to_s.split(";").map(&:strip).reject(&:empty?))
end
consulted_sigla_by_source_id.each_value(&:uniq!)

CSV.parse(File.read("housekeeping/psmd/enhance_list.tsv"), col_sep: "\t", headers: %i[psmd_id muscat_id]).each do |r|

  ms = PsmdConversion.legacy.find(:manuscripts, r[:psmd_id])
  PsmdConversion.set_log_context(
    current_psmd_manuscript_ext_id: ms && ms["ext_id"],
    current_psmd_manuscript_id: ms && ms["id"],
    current_muscat_source_id: r[:muscat_id]
  )
  unless ms
    PsmdConversion.log_event(
      :missing_legacy_reference,
      record_type: "manuscript",
      psmd_reference_id: r[:psmd_id]
    )
  end

  # GndWork loads ALL numbers as marc tags
  old = MarcGndWork.new(ms["source"])
  old.load_source false

  begin
    source = Source.find(r[:muscat_id])
  rescue ActiveRecord::RecordNotFound
    warn "Source #{r[:muscat_id]} was deleted".red
    next
  end
  PsmdConversion.update_log_context(current_muscat_source_id: source.id)

  PsmdConversion.copy_from_source_marc(
    old,
    source.marc,
    copy_map,
    log_context: {
      psmd_manuscript_ext_id: ms["ext_id"],
      psmd_manuscript_id: ms["id"],
      muscat_source_id: source.id
    }
  )

  source.marc.add_tag_with_subfields("599", a: "Merged from PSMD manuscripts/#{ms["ext_id"]} (internal id #{ms["id"]})")
  #source.marc.add_tag_with_subfields("691", "0": 50006603, u: "http://printed-sacred-music.org/manuscripts/#{ms["ext_id"]}")
  source.marc.add_tag_with_subfields("910", "0": 51009572)

  source_saved = source.save
  PsmdConversion.log_persistence_error(
    source,
    psmd_manuscript_ext_id: ms["ext_id"],
    psmd_manuscript_id: ms["id"],
    muscat_parent_source_id: source.id
  ) unless source_saved
  source.reindex
  PsmdConversion.log_event(
    :source_mapping,
    action: source_saved ? "extended" : "extension failed",
    psmd_input_id: r[:psmd_id],
    psmd_manuscript_ext_id: ms["ext_id"],
    psmd_manuscript_id: ms["id"],
    muscat_source_id: source.id
  )
  # LOG Migrated PSMD id to Muscat id
  puts "PSMD #{r[:psmd_id]} to #{source.id}"

  PsmdConversion.attach_508_markdown(old, source, ms["ext_id"], psmd_manuscript_id: ms["id"])

  modified_sources.add_item(source)
  
  PsmdConversion.create_holding_records(source, old, ms, holding_folder)

  added_588 = []
  has_588 = !source.marc["588"].empty?
  if consulted_sigla_by_source_id.key?(source.id.to_s)
    unless has_588
      consulted_sigla_by_source_id[source.id.to_s].each do |siglum|
        source.marc.add_tag_with_subfields("588", a: siglum)
        added_588 << siglum
      end
    end
  else
    holdings = source.holdings.reload.to_a
    if holdings.length == 1
      siglum = holdings.first.lib_siglum.to_s.strip
      if has_588
        action = "588 already exists; no siglum added"
      elsif !siglum.empty?
        source.marc.add_tag_with_subfields("588", a: siglum)
        added_588 << siglum
        action = "added single holding lib_siglum to 588"
      else
        action = "single holding has no lib_siglum"
      end
    elsif holdings.length > 1
      action = has_588 ? "multiple holdings; existing 588 retained" : "multiple holdings; 588 not added"
    end

    if holdings.length > 0
      PsmdConversion.log_event(
        :unlisted_consulted_source,
        muscat_source_id: source.id,
        psmd_manuscript_ext_id: ms["ext_id"],
        psmd_manuscript_id: ms["id"],
        holding_count: holdings.length,
        holding_sigla: holdings.map(&:lib_siglum).compact.join("; "),
        action: action
      )
    end
  end

  unless added_588.empty?
    source_saved = source.save
    PsmdConversion.log_persistence_error(
      source,
      psmd_manuscript_ext_id: ms["ext_id"],
      psmd_manuscript_id: ms["id"],
      muscat_parent_source_id: source.id
    ) unless source_saved
    source.reindex
  end

  existing_child_ids = source.child_sources.pluck(:id)
  if existing_child_ids.empty?
    count = PsmdConversion.migrate_child_records(source, old, ms, child_folder)

    if count > 0
      rism_title = source.marc["240"].first&.[]("a")&.first&.content
      psmd_title = source.marc["730"].first&.[]("a")&.first&.content
      suggested_title = "#{count} #{rism_title}"

      # LOG proposed standard title
      PsmdConversion.log_event(
        :proposed_standard_title,
        muscat_parent_source_id: source.id,
        psmd_manuscript_ext_id: ms["ext_id"],
        psmd_manuscript_id: ms["id"],
        created_child_count: count,
        rism_title: rism_title,
        suggested_title: suggested_title,
        psmd_title: psmd_title
      )
      puts ["STDTITLE", source.id, ms["ext_id"], rism_title, suggested_title, psmd_title].join("\t")
    end
  else
    # LOG skipped child creation because parent has children
    PsmdConversion.log_event(
      :skipped_children,
      muscat_parent_source_id: source.id,
      psmd_manuscript_ext_id: ms["ext_id"],
      psmd_manuscript_id: ms["id"],
      existing_child_count: existing_child_ids.length,
      existing_child_source_ids: existing_child_ids.join(",")
    )
  end

  # MAke the GC happy? I guess?
  source = nil

end

# Removed
# 2493	990048328

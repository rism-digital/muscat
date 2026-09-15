require_relative 'legacy_file.rb'

legacy = LegacyFile.new("housekeeping/psmd/psmd.yml")
@people_map = YAML.load_file("housekeeping/psmd/psmd_people.yml")
@institution_map = YAML.load_file("housekeeping/psmd/psmd_institutions.yml")
@siglum_map = YAML.load_file("housekeeping/psmd/psmd_siglums.yml")

@publication_map = {
  "100002" => 1457,
  "100004" => 1272,
  "100006" => 30028344,
  "100003" => 3332,
  "100007" => 41000451,
  "400000" => 3509
}

the_short_list = %w[
3710
3714
3820
337
3815
1222
3814
3573
2000
2000
3631
1378
3721
2563
3557
3765
3688
3644
3719
3723
3725
3726
3728
3744
3743
871
1220
1257
1298
2552
3698
3698
3699
3699
3707
3711
3712
3724
3724
3741
3742
3821
794
864
1798
2014
2014
3737
3739
3713
3745
3746
3748
3749
3751
3643
3708
3720
3717
3717
3136
1221
3802
]

#ap legacy.all(:manuscripts).first

def copy_from_source_marc(source, dest)
  copy_map = [
    {
      from: "040",
      to: "040",
      subfields: { "b" => "b" }
    },
    {
      from: "100",
      to: "100",
      subfields: {"a" => "a", "d" => "d", "0" => "0" },
      map: @people_map
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
      from: "246",
      to: "246",
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
      subfields: {"d" => "d" }
    }, 
    {
      from: "596",
      to: "596",
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
      map: @publication_map
    }, 
    {
      from: "691",
      to: "691",
      subfields: { "a" => "a", "n" => "n", "0" => "0" },
      map: @publication_map
    },
    {
      from: "700",
      to: "700",
      subfields: { "a" => "a", "4" => "4", "0" => "0" },
      map: @people_map
    }, 
    {
      from: "710",
      to: "710",
      subfields: {"a" => "a", "4" => "4", "0" => "0" },
      map: @institution_map
    }, 
  ]

  destroyed = {}

  copy_map.each do |rule|
    source[rule[:from]].each do |source_tag|
      values = {}

      rule[:subfields].each do |source_sf, dest_sf|
        source_tag[source_sf].each do |subfield|
          kill = false

          if source_sf == "0" && rule.include?(:map)
            if rule[:map].include?(subfield.content.to_s)
              subfield.content = rule[:map][subfield.content]
            else
              name = source_tag["a"]&.first&.content
              puts "#{source_tag.tag} ID not mapped #{subfield.content}\t#{name}".red
              #puts source_tag
              subfield.destroy_yourself
              kill = true
            end
          end

          (values[dest_sf.to_sym] ||= []) << subfield.content if !kill
        end
      end

      next if values.empty?

      # Make sure group tags are in group 01, there were not groups in PSMD
      if rule[:to] == "260" || rule[:to] == "300" || rule[:to] == "340"
        values["8"] = "01"
      end

      unless destroyed[rule[:to]]
        dest[rule[:to]].each(&:destroy_yourself) unless dest[rule[:to]].empty?
        destroyed[rule[:to]] = true
      end

      dest.add_tag_with_subfields(rule[:to], **values)
    end
  end

end

#default_file_name = EditorConfiguration.get_source_default_file("edition")
#default_file = ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/source/#{default_file_name}.marc")
#def_marc = File.read(default_file)

def zip_get_named_file(filename)
  Zip::File.open("housekeeping/psmd/incipits.zip") do |zip|
    entry = zip.find_entry(filename)
    return nil unless entry

    entry.get_input_stream.read
  end
end

def mini_parse_pae(data)
  body = data.sub(/\A@data:\s*/m, "").strip

  clef   = body[/%(\S+)/, 1]
  keysig = body[/\$(\S+)/, 1]

  notes = body
    .sub(/%\S+\s*/, "")
    .sub(/\$\S+\s*/, "")
    .sub(/@\s*/, "")
    .strip

  {
    clef: clef,
    keysig: keysig,
    notes: notes
  }
end

def extract_darms_text(darms)
  return "" unless darms.include?("@")

  text = darms.split("@", 2).last
  text = text.split("$", 2).first if text.include?("$")
  text = text.split(/\d/, 2).first unless darms.split("@", 2).last.include?("$")

  text.strip
end

def darms_timesig_to_pae(darms)
  code = darms[/!M(?:C\/?|[0-9]+:[0-9]+)/]
  return nil unless code

  case code
  when "!MC"
    "c"
  when "!MC/"
    "c/"
  when "!M3:1"
    "3/1"
  when "!M3:2"
    "3/2"
  when "!M3:4"
    "3/4"
  else
    warn "Unsupported DARMS time signature: #{code}"
    nil
  end
end

def migrate_child_records(legacy, source, old_marc, ms)
  
  ids = old_marc["600"].map do |t|
    t["0"]&.first&.content
  end.compact

  ids.each do |id|
    work = legacy.find_by(:works, :ext_id, id.to_i)
    incipits = legacy.where(:work_incipits, work_id: work["id"])

    child = Source.new
    child.record_type = 3
    child.source_id = source.id

    marc = MarcSource.new("=001 __TEMP__", 3)
    marc.reset_to_new

    person = legacy.find_by(:people, :id, work["person_id"].to_i)

    #ap person["ext_id"]
    #ap @people_map[person["ext_id"].to_s]

    std_title_candidate = ""

    incipits.each_with_index do |incipit, i|
      pae_line = zip_get_named_file("incipits/pae/work_incipit_#{incipit["ext_id"]}.pae")
      pae = mini_parse_pae(pae_line)
      
      marc.add_tag_with_subfields("031", 
        a: "1", b: "1", c: i + 1, 
        m: incipit["instrument_or_voice"], 
        n: pae[:keysig], g: pae[:clef], p: pae[:notes],
        # FIXME this was not translated?
        o: darms_timesig_to_pae(incipit["notation"]),
        t: extract_darms_text(incipit["notation"]),
        q: incipit["public_note"],
      )

      # Use the first one for the standard title
      std_title_candidate = extract_darms_text(incipit["notation"]) if i == 0
    end

    marc.add_tag_with_subfields("240", a: std_title_candidate) if !std_title_candidate.empty?
    marc.add_tag_with_subfields("100", "0": @people_map[person["ext_id"].to_s])
    marc.add_tag_with_subfields("245", a: work["title"])
    marc.add_tag_with_subfields("773", w: source.id)
    marc.add_tag_with_subfields("500", a: "Created from PSMD works/#{work["ext_id"]} in  manuscripts/#{ms["ext_id"]} (#{ms["id"]})")
    marc.add_tag_with_subfields("691", "0": 50006603)
    marc.import

    child.marc = marc
    child.save

    puts "\tCreated #{child.id}"
  end

end

def create_holding_records(legacy, source, old, ms)

  old["852"].each do |t|
    #sig = t["a"]&.first&.content
    id = t["0"]&.first&.content
    material_held = t["3"]&.first&.content
    #notes = t["z"]&.first&.content
    shelfmark = t["p"]&.first&.content

    h = Holding.new
    marc = MarcHolding.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/holding/default.marc")))
    marc.load_source false

    marc.by_tags("852").each {|t| t.destroy_yourself}
    marc.by_tags("500").each {|t| t.destroy_yourself}

    muscat_id = @siglum_map[id.to_s]
    marc.add_tag_with_subfields("852", x: muscat_id, c: shelfmark, q: material_held)
    marc.add_tag_with_subfields("500", a: "Created from PSMD manuscripts/#{ms["ext_id"]} (#{ms["id"]})")

    t["z"].each do |note|
      marc.add_tag_with_subfields("500", a: note&.content)
    end

    marc.import

    h.marc = marc
    h.source = source
    h.save

    puts "Created holding #{h.id}"

  end
end


the_short_list.each do |m|
  
  ms = legacy.find(:manuscripts, m)

  # GndWork loads ALL numbers as marc tags
  old = MarcGndWork.new(ms["source"])
  old.load_source false

  new = MarcSource.new("=001 __TEMP__", 8)
  new.reset_to_new

  copy_from_source_marc(old, new)
  new.add_tag_with_subfields("500", a: "Imported from PSMD manuscripts/#{ms["ext_id"]} (#{ms["id"]})")
  new.add_tag_with_subfields("691", "0": 50006603)
  new.import

  source = Source.new
  source.user = User.find(74)
  source.marc = new
  source.record_type = 8

  source.save
  puts "PSMD #{m} to #{source.id}"
  
  create_holding_records(legacy, source, old, ms)

  migrate_child_records(legacy, source, old, ms)

end
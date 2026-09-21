require_relative 'legacy_file.rb'
require "reverse_markdown"
require "stringio"

module PsmdConversion
  extend self

  attr_reader :legacy, :people_map, :institution_map, :publication_map

  USER_ID = 74 #me

  @legacy = LegacyFile.new(File.join(__dir__, "psmd.yml"))
  @people_map = YAML.load_file(File.join(__dir__, "psmd_people.yml"))
  @institution_map = YAML.load_file(File.join(__dir__, "psmd_institutions.yml"))
  @siglum_map = YAML.load_file(File.join(__dir__, "psmd_siglums.yml"))
  
  @publication_map = {
    "100002" => 1457,
    "100004" => 1272,
    "100006" => 30028344,
    "100003" => 3332,
    "100007" => 41000451,
    "400000" => 3509
  }

  @subject_map = {
    "Antifona" => 25235,
    "Cantata" => 25226,
    "Hymn" => 25238,
    "Inno" => 25238,
    "Introit" => 25150,
    "Madrigale" => 25257,
    "Magnificat" => 25478,
    "Mass" => 25133,
    "Mass (Requiem)" => 25134,
    "Motet" => 25240,
    "Motet - Marian antiphon" => 3901679,
    "Motet -- Marian antiphon" => 3901679,
    "Mottetto" => 25240,
    "Oratorio" => 25230,
    "Psalm" => 3000057,
    "Sonata" => 25213,
    "antifona" => 25235,
    "cantico" => 25478,
    "canticum" => 25478,
    "cantio sacra" => 25250,
    "canzona da sonar" => 25358,
    "canzona spirituale (16.-17. sec.)" => 25258,
    "canzone da sonar" => 25358,
    "canzone per l'Epistola" => 25358,
    "canzone spirituale (16.-17. sec.)" => 25258,
    "canzonetta spirituale (16.-17. sec.)" => 25315,
    "compieta" => 3901027,
    "concerto ecclesiastico (vocale)" => 25362,
    "concerto sacro (17. sec.)" => 25362,
    "dialogo" => 25330,
    "entrata" => 25370,
    "falsobordone" => 3900119,
    "graduale" => 25239,
    "improperia" => 25157,
    "inno" => 25238,
    "intonazione" => 25350,
    "introito" => 25150,
    "invitatorio" => 25489,
    "invitatorium" => 25489,
    "kyrie" => 25133,
    "lamentazione" => 25241,
    "lauda" => 3900350,
    "lezioni di geremia" => 25241,
    "litania" => 25137,
    "lodi (liturgiche)" => 25145,
    "lodi sacre (non liturgiche)" => 3900350,
    "madrigal" => 25257,
    "madrigale" => 25257,
    "madrigale spirituale" => 25257,
    "magnificat" => 25478,
    "messa" => 25133,
    "miserere" => 3000057,
    "mocteto" => 25240,
    "motet" => 25240,
    "motetto" => 25240,
    "mottetto" => 25240,
    "mottetto concertato" => 25240,
    "offertorio" => 25242,
    "officium" => 25145,
    "passio" => 25246,
    "requiem" => 25134,
    "responsorio" => 25248,
    "responsorium" => 25248,
    "sacrae cantiones" => 25250,
    "salmo" => 3000057,
    "salve regina" => 3901679,
    "sequenza" => 25249,
    "sinfonia" => 25215,
    "sonata" => 25213,
    "tantum ergo" => 3005240,
    "te deum" => 25238,
    "tractus" => 25156,
    "vespro" => 25149,
  }

def convert_weird_characters(text)
  text.to_s
    .tr("ſ", "s")
    .gsub("æ", "ae")
    .gsub("Æ", "AE")
    .gsub("ĉ", "c")
    .gsub("Ĉ", "C")
end

def sanitize_weird_text(title)
  convert_weird_characters(ActionView::Base.full_sanitizer.sanitize(title))
end

def convert_508_html_to_markdown(content)
  html = Nokogiri::HTML.fragment(convert_weird_characters(content))
  html.css("sup").each do |node|
    superscript = node.text.strip
    replacement = if superscript.length <= 20 && !superscript.match?(/[()|\r\n]/)
      "^(#{superscript})"
    else
      superscript
    end

    node.replace(Nokogiri::XML::Text.new(replacement, html.document))
  end

  ReverseMarkdown.convert(
    html.to_html,
    github_flavored: true,
    unknown_tags: :bypass
  ).strip
end

def extract_508_markdown(marc)
  marc["508"].flat_map do |tag|
    tag["a"].filter_map do |subfield|
      markdown = convert_508_html_to_markdown(subfield.content)
      markdown unless markdown.empty?
    end
  end.join("\n\n")
end

def attach_508_markdown(marc, source, psmd_id)
  markdown = extract_508_markdown(marc)
  return if markdown.empty?

  filename = "text.md"
  description = psmd_id.to_s
  user = User.find(USER_ID)

  DigitalObject.transaction do
    digital_object = source.digital_objects.find_by(
      attachment_file_name: filename,
      description: description
    ) || DigitalObject.new
    attachment = StringIO.new(markdown)
    attachment.define_singleton_method(:original_filename) { filename }
    attachment.define_singleton_method(:content_type) { "text/markdown" }

    digital_object.description = description
    digital_object.user = user
    digital_object.attachment = attachment
    digital_object.save!

    DigitalObjectLink.find_or_create_by!(
      digital_object: digital_object,
      object_link: source
    ) do |link|
      link.user = user
    end

    digital_object
  end
end

def copy_from_source_marc(source, dest, copy_map)
  destroyed = {}

  copy_map.each do |rule|
    source[rule[:from]].each do |source_tag|
      values = {}

      rule[:subfields].each do |source_sf, dest_sf|
        source_tag[source_sf].each do |subfield|
          dont_preserve = false

          if source_sf == "0" && rule.include?(:map)
            if rule[:map].include?(subfield.content.to_s)
              subfield.content = rule[:map][subfield.content]
            else
              # Do not preserve unmapped values
              name = source_tag["a"]&.first&.content
              puts "#{source_tag.tag} ID not mapped #{subfield.content}\t#{name}".red
              #puts source_tag
              subfield.destroy_yourself
              dont_preserve = true
            end
          end

          # Remove HTML in the original tags
          sanitized_content = sanitize_weird_text(subfield.content.to_s)

          (values[dest_sf.to_sym] ||= []) << sanitized_content if !dont_preserve
        end
      end

      next if values.empty?

      # Create 730s to shut muscat up
      if rule[:to] == "730"
        st = StandardTitle.where(title: values[:a]&.first)
        if st.count == 0
          st = StandardTitle.new(title: values[:a]&.first, notes: "Created from PSMD parent")
          st.save
          (values["0"] ||= []) << st.id
        else
          (values["0"] ||= []) << st.first.id
        end
      end

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
  if Dir.exist?(File.join(__dir__, "incipits"))
    path = File.join(__dir__, filename)
    return File.exist?(path) ? File.read(path) : nil
  end

  Zip::File.open(File.join(__dir__, "incipits.zip")) do |zip|
    entry = zip.find_entry(filename)
    return nil unless entry

    entry.get_input_stream.read
  end
end

def mini_parse_pae(data)
  if data.nil?
    puts "COULD NOT READ PAE or NO PAE".yellow
    return {}
  end

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
  when "!M6:8"
    "6/8"
  when "!M3:8"
    "3/8"
  when "!M8:6"
    "6/8"
  when "!M6:4"
    "6/4"
  when "!M5:4"
    "5/4"
  when "!M2:4"
    "2/4"
  when "!M03:1"
    "o3"
  when "!M12:8"
    "12/8"
  when "!M4:6"
    "6/4"
  else
    warn "Unsupported DARMS time signature: #{code}"
    nil
  end
end

def migrate_child_records(source, old_marc, ms, folder = nil)
  
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

    if incipits.count == 0
      warn "SKIP EMPTY WORK #{work["ext_id"]}".red
      next
    end


    
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

    # If there is not text in 031 try to use the title property
    # Which is wonky
    if std_title_candidate.empty?
      std_title_candidate = work["title"]&.sub(/\A(['"])(.*)\1\z/, '\2')
    end

    # Create the 240 by hand so we can put a "creation note"
    # in the notes field
    if std_title_candidate && !std_title_candidate.empty?
      st_id = nil

      st = StandardTitle.where(title: std_title_candidate)
      if st.count == 0
        st = StandardTitle.new(title: std_title_candidate, notes: "Created from PSMD child works/#{work["ext_id"]} in parent #{source.id}")
        st.save
        st_id = st.id
      else
        st_id = st.first.id
      end

      marc.add_tag_with_subfields("240", "0": st_id, a: std_title_candidate)
    end

    # Try to convert the FORM to 650
    if work["form"] && !work["form"].empty? && @subject_map.include?(work["form"])
      marc.add_tag_with_subfields("650", "0": @subject_map[work["form"]])
    else
      # poach it from the parent
      #par_650 = source.marc["650"].map do |t|
      #  t["0"]&.first&.content
      #end.first
      #par_650 = source.marc["650"].first&.dig("0")&.first&.content
      par_650 = source.marc["650"].first&.[]("0")&.first&.content
      marc.add_tag_with_subfields("650", "0": par_650) if par_650
    end

    marc.add_tag_with_subfields("100", "0": @people_map[person["ext_id"].to_s])
    marc.add_tag_with_subfields("245", a: work["title"])
    marc.add_tag_with_subfields("773", w: source.id)
    marc.add_tag_with_subfields("599", a: "Created from PSMD works/#{work["ext_id"]} in manuscripts/#{ms["ext_id"]} (#{ms["id"]})")
    #marc.add_tag_with_subfields("691", "0": 50006603)
    marc.add_tag_with_subfields("910", "0": 51009572)

    marc.import

    child.marc = marc
    child.user = User.find(USER_ID)
    child.save
    child.reindex
    # I know it is a moxture between dumb and evil
    # Force all the links to be pulled
    c2 = Source.find(child.id)
    c2.save

    puts "\tCreated #{child.id}"
    folder.add_item(child) if folder
  end

end

def create_holding_records(source, old, ms, folder = nil)

  institution_ids = source.holdings.flat_map do |holding|
    holding.marc["852"].flat_map { |tag| tag["x"].map { |sf| sf.content.to_s } }
  end

  old["852"].each do |t|
    #sig = t["a"]&.first&.content
    id = t["0"]&.first&.content
    material_held = t["3"]&.first&.content
  #notes = t["z"]&.first&.content
    shelfmark = t["p"]&.first&.content

    #ll = Institution.where(siglum: t["a"]&.first&.content).map(&:id).join(" ")
    #puts "LIBRARY #{t["a"]&.first&.content} \"#{id}\" => #{ll}"

    muscat_id = @siglum_map[id.to_s]

    if muscat_id == "delete"
      puts "Skip #{id.to_s} #{t["a"]&.first&.content} as requested".yellow
      return
    end

    if !@siglum_map.include? id.to_s
      puts "PSMD siglum #{t["a"]&.first&.content} #{id} does not exist in muscat, skip".magenta
      next
    end

    if institution_ids.include?(muscat_id.to_s)
      puts "PSMD Library #{muscat_id.to_s} (#{t["a"]&.first&.content}) already has a holding record in #{ms["ext_id"]}".blue
      next
    end

    h = Holding.new
    marc = MarcHolding.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/holding/default.marc")))
    marc.load_source false

    marc.by_tags("852").each {|t| t.destroy_yourself}
    marc.by_tags("500").each {|t| t.destroy_yourself}

    marc.add_tag_with_subfields("852", x: muscat_id, c: shelfmark, q: material_held)
    #marc.add_tag_with_subfields("599", a: "Created from PSMD manuscripts/#{ms["ext_id"]} (internal id #{ms["id"]})")

    t["z"].each do |note|
      marc.add_tag_with_subfields("500", a: note&.content)
    end

    marc.import

    h.marc = marc
    h.source = source
    # Let us make duplicates
    #institution_ids << muscat_id.to_s if h.save
    h.user = User.find(USER_ID)
    h.save

    puts "Created holding #{h.id}"

    folder.add_item(h) if folder

    h2 = Holding.find(h.id)
    h2.save

  end
end

end

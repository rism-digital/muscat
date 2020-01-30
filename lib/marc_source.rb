class MarcSource < Marc
  
  # record_type mapping
  RECORD_TYPES = {
    unspecified: 0,
    collection: 1,
    source: 2,
    edition_content: 3,
    libretto_source: 4,
    libretto_edition: 5,
    theoretica_source: 6,
    theoretica_edition: 7,
    edition: 8,
    libretto_edition_content: 9,
    theoretica_edition_content: 10,
    composite_volume: 11,
  }
  
  RECORD_TYPE_ORDER = [
    :collection,
    :source,
    :libretto_source,
    :theoretica_source,
    :edition,
    :edition_content,
    :libretto_edition,
    :theoretica_edition,
    :libretto_edition_content,
    :theoretica_edition_content,
    :composite_volume,
    :unspecified
  ]

  def self.is_edition?(record_type)
    
    if record_type.is_a? String
      record_type = RECORD_TYPES[record_type.to_sym]
    elsif record_type.is_a? Symbol
      record_type = RECORD_TYPES[record_type]
    end
    
    [MarcSource::RECORD_TYPES[:edition],
    MarcSource::RECORD_TYPES[:edition_content],
    MarcSource::RECORD_TYPES[:libretto_edition],
    MarcSource::RECORD_TYPES[:theoretica_edition],
    MarcSource::RECORD_TYPES[:libretto_edition_content],
    MarcSource::RECORD_TYPES[:theoretica_edition_content]].include? record_type
  end

  def initialize(source = nil, rt = 0)
    super("source", source)
    @record_type = rt
  end
  
  def record_type
    @record_type
  end
  
  # Get the std_title and std_title_d values  
  def get_std_title  
    std_title = ""
    std_title_d = ""
    standard_title = nil
    scoring = nil
    extract = nil
    arr = nil
    
    # try to get the title (240)
    # Quartets
    node = first_occurance("240", "a")
    standard_title = node.content.truncate(50) if node && node.content
    standard_title.strip! if standard_title
    
    # try to get the description (240 m)
    # vl (2), vla, vlc
    node = first_occurance("240", "m")
    scoring = node.content.truncate(50) if node && node.content
    scoring.strip! if scoring
   
    node = first_occurance("240", "k")
    extract = node.content.truncate(50) if node && node.content
    extract.strip! if extract
    
    node = first_occurance("240", "o")
    arr = node.content.truncate(50) if node && node.content
    arr.strip! if arr
   
    node = first_occurance("383", "b")
    opus = node.content.truncate(50) if node && node.content
    opus.strip! if opus
   
    node = first_occurance("690", "a")
    cat_a = node.content.truncate(50) if node && node.content
    cat_a.strip! if cat_a
    
    node = first_occurance("690", "n")
    cat_n = node.content.truncate(50) if node && node.content
    cat_n.strip! if cat_n
   
    cat_no = "#{cat_a} #{cat_n}".strip
    cat_no = nil if cat_no.empty? # For the join only nil is skipped 
   
    if !standard_title
      if @record_type == RECORD_TYPES[:collection]
        standard_title = "[Collection]"
      end
    end
    
    title = (standard_title != nil || standard_title != "") ? standard_title : "[Without title]" ## if title is unset and it is not collection

    desc = [extract, arr, scoring, opus, cat_no].compact.join("; ")
    desc = nil if desc.empty?
    
    # use join so the "-" is not places if one of the two is missing
    std_title = [title, desc].compact.join(" - ")
    std_title_d = DictionaryOrder::normalize(std_title)

    [std_title, std_title_d]
  end
  
  # Get the composer and composer_d values
  def get_composer
    composer = ""
    composer_d = ""
    if node = first_occurance("100", "a")
      person = node.foreign_object
      composer = person.full_name
      composer_d = person.full_name_d
    end
    [composer, composer_d]
  end

  def get_siglum
    if node = first_occurance("852", "a")
      return node.content
    end
  end
    
  # Get the Library and shelfmarc for a MARC record
  def get_siglum_and_shelf_mark
    siglum = "" 
    ms_no = ""
    
    tags_852 = by_tags(["852"])    
    if tags_852.length > 1 # we have multiple copies
      tags_852.each do |tag|
				t = tag.fetch_first_by_tag("a")
				next if !t || !t.content
        a_tag = t.content
        siglum = siglum == "" ? "#{a_tag}" : "#{siglum}, #{a_tag}"
      end
      #siglum = "[multiple copies]"
      ms_no = "[multiple copies]"
          
    elsif tags_852.length == 1 # single copy
      if node = first_occurance("852", "a")
        siglum = node.foreign_object.siglum
        siglum = "" if !siglum
      end
      if node = first_occurance("852", "c")
        ms_no = node.content if node.content
      end
    end
    
    return [siglum.truncate(255), ms_no.truncate(255)]
  end
  
  # On RISM A/1 ms_no contains the OLD RISM ID, get it from 035
  def get_book_rism_id
    if node = first_occurance("035", "a")
      return node.content
    end
  end

  
  # For bibliographic records, set the ms_title and ms_title_d field fromMARC 245 or 246
  def get_source_title
    ms_title = "[unset]"  
    ms_title_field = (RISM::BASE == "in") ? "246" : "245" # one day the ms_title field (and std_title field) should be put in the environmnent.rb file
    if node = first_occurance(ms_title_field, "a")
      ms_title = node.content
    end

    ms_title_d = DictionaryOrder::normalize(ms_title)
   
    return [ms_title.truncate(255), ms_title_d.truncate(255)]
  end
  
  # Set miscallaneous values
  def get_miscellaneous_values

    language = "Unknown"
    date_from = nil
    date_to = nil

    ## Language is not used anumore
    #if node = first_occurance("008")
    #  unless node.content.empty?
    #    language = LANGUAGES[marc_helper_get_008_language(node.content)] || "Unknown"
    #  end
    #end

    out = []
    each_by_tag("260") do |marctag|
      marctag.each_by_tag("c") do |marcsubtag|
        out.concat(date_to_array(marcsubtag.content)) if marcsubtag && marcsubtag.content
      end
    end
    
    out.sort!.uniq!
    if out.count > 0
      if out.count > 1
        date_from = out.first
        date_to = out.last
      else
        date_from = date_to = out[0]
      end
    end
    
    return [language.truncate(16), date_from, date_to]

  end
  
  def reset_to_new
    #load_source false if !@loaded
    first_occurance("001").content = "__TEMP__"
    by_tags("774").each {|t| t.destroy_yourself}
  end

  def match_leader
    rt = RECORD_TYPES[:unspecified]
    
    leader = nil
    if first_occurance("000") && first_occurance("000").content
      leader = first_occurance("000").content
    else
      puts "No leader present"
      return nil
    end
    
    if leader.match(/......[dcp]c.............../)
      rt = RECORD_TYPES[:collection]
    elsif leader.match(/......pd.............../) # Mixed material, subunit, ex convolutum
      rt = RECORD_TYPES[:collection]
    elsif leader.match(/......d[dm].............../)
      rt = RECORD_TYPES[:source]
    elsif leader.match(/......c[dm].............../)
      rt = RECORD_TYPES[:edition_content]
    elsif leader.match(/......tm.............../)
      rt = RECORD_TYPES[:libretto_source]
    elsif leader.match(/......am.............../)
      rt = RECORD_TYPES[:libretto_edition]
    elsif leader.match(/......pm.............../) # Mixed material, item
      rt = RECORD_TYPES[:source]
    else
       puts "Unknown leader #{leader}"
    end
    
    return rt
  end
  
  def to_internal
    # convert leader to record_type
    rt = match_leader
    
    # Drop leader
    by_tags("000").each {|t| t.destroy_yourself}
     
    # Drop other unused tags
    by_tags("003").each {|t| t.destroy_yourself}
    by_tags("005").each {|t| t.destroy_yourself}
    by_tags("007").each {|t| t.destroy_yourself}
    by_tags("008").each {|t| t.destroy_yourself}
    
    # Move 130 to 240
    each_by_tag("130") do |t|

      node = t.deep_copy
      node.tag = "240"
      node.indicator = "10"
      node.sort_alphabetically
      root.children.insert(get_insert_position("240"), node)
      
      t.destroy_yourself
      
    end
    
    each_by_tag("240") do |t|
      t.each_by_tag("n") do |st|
        st.destroy_yourself if st
      end
    end
    
    # Drop $2pe in 031, see #194
    each_by_tag("031") do |t|
      st = t.fetch_first_by_tag("2")
      if st && st.content && st.content != "pe"
        puts "Unknown 031 $2 value: #{st.content}"
      end
      st.destroy_yourself if st
    end
    
    # Remove the $a tag
    a = by_tags("594")
    a.each do |t|
      t.each_by_tag("a") do |st|
        st.destroy_yourself if st
      end
      
      # it the 594 is then empty remove it
      if t.all_children.count == 0
        t.destroy_yourself
      end
    end
    
    each_by_tag("691") do |t|
      t.each_by_tag("c") do |st|
        st.destroy_yourself if st
      end
    end
    
    each_by_tag("774") do |t|
      t.each_by_tag("t") do |st|
        st.destroy_yourself if st
      end
    end
    
    ## BUSH FIX
    ## #350
    # remove 700 with DE-588a links
    # these are IDS that do not exist in muscat
    a = by_tags("700")
    a.each do |t|
      st = t.fetch_first_by_tag("0")
      if st && st.content
        if st.content.include?("DE-588a")
          $stderr.puts "#{get_id}: ".magenta + "Killing 700 tag: ".green + t.to_s.yellow
          t.destroy_yourself
        end
      end
    end
    
    ## BUSH FIX
    ## #350
    # Kill 852 with $a but empty $x
    a = by_tags("852")
    a.each do |t|
      st = t.fetch_first_by_tag("a")
      stx = t.fetch_first_by_tag("x")
      if st && st.content
        if stx && stx.content.empty?
          $stderr.puts "#{get_id}: ".magenta + "Killing 852 tag: ".green + t.to_s.yellow 
          t.destroy_yourself
        end
      end
    end
    
    if rt
      @record_type = rt
    end
  end
  
  def to_external(updated_at = nil, versions = nil, holdings = true)
    super(updated_at, versions)
    parent_object = Source.find(get_id)
    # See #176
    # Step 1, rmake leader
    # collection, if we have prints only (......cc...............) or not (......dc...............)
    # manuscript and print, if it is part of a collection (......[cd]d...............) or not (......[cd]m...............)

    base_leader = "00000nXX#a2200000#u#4500"

    if ((@record_type == RECORD_TYPES[:collection]) || (@record_type == RECORD_TYPES[:edition]))
      type = "cc"
      
      each_by_tag("774") do |t|
        w = t.fetch_first_by_tag("w")
        if w && w.content
          source = Source.find(w.content) rescue next
          type = "dc" if source.record_type != RECORD_TYPES[:edition_content]
          t.add_at(MarcNode.new(@model, "a", source.name, nil), 0)
        else
          raise "Empty $w in 774"
        end
      end
      
      leader = base_leader.gsub("XX", type)
    elsif @record_type == RECORD_TYPES[:composite_volume]
      leader = base_leader.gsub("XX", 'pc')
    elsif @record_type == RECORD_TYPES[:source]
      type = "dm"
      type = "dd" if by_tags("773").count > 0
      leader = base_leader.gsub("XX", type)
    elsif @record_type == RECORD_TYPES[:edition_content]
      type = "cm"
      type = "cd" if by_tags("773").count > 0
      leader = base_leader.gsub("XX", type)
    elsif @record_type == RECORD_TYPES[:libretto_source]
      leader = base_leader.gsub("XX", "tm")
    elsif @record_type == RECORD_TYPES[:libretto_edition]
      leader = base_leader.gsub("XX", "am")
    elsif @record_type == RECORD_TYPES[:theoretica_source] # we cannot make the distinction between ms and print
      leader = base_leader.gsub("XX", "pm")
    else
      puts "Unknown record type #{@record_type}"
      leader = ""
    end
    
    new_leader = MarcNode.new("source", "000", leader, "")
    @root.children.insert(get_insert_position("000"), new_leader)

    # 240 to 130 when 100 is not present
    if by_tags("100").count == 0
      each_by_tag("240") do |t|
        node = t.deep_copy
        node.tag = "130"
        node.indicator = "0#"
        node.sort_alphabetically
        root.children.insert(get_insert_position("130"), node)
        t.destroy_yourself
      end
    end
    
    # Put back $2pe in 031, see #194
    each_by_tag("031") do |t|
      t.add_at(MarcNode.new("source", "2", "pe", nil), 0)
      t.sort_alphabetically
    end

    # copy 691$n to 035 to have the local B/I id with collections
    if parent_object.record_type == 8 && parent_object.id.to_s =~ /^993/
      n035 = nil
      each_by_tag("691") do |t|
        b1 = t.fetch_first_by_tag("a").content rescue next
        number = t.fetch_first_by_tag("n").content rescue next
        if b1 && b1 == 'RISM B/I'
          n035 = MarcNode.new("source", "035", "", "##")
          n035.add_at(MarcNode.new("source", "a", number, nil), 0)
        end
      end
      root.children.insert(get_insert_position("035"), n035) if n035
    end
    
    # Add 040 if not exists; if 040$a!=DE-633 then add 040$c
    if by_tags("040").count == 0
        n040 = MarcNode.new(@model, "040", "", "##")
        n040.add_at(MarcNode.new(@model, "a", RISM::AGENCY, nil), 0)
        root.children.insert(get_insert_position("040"), n040)
    else
      each_by_tag("040") do |t|
        existent = t.fetch_first_by_tag("a").content rescue nil
        if existent && existent != RISM::AGENCY
          t.add_at(MarcNode.new("source", "c", RISM::AGENCY, nil), 0)
          t.sort_alphabetically
        end
      end
    end

    #340 Add a 594 with $a
    scorings = []
    each_by_tag("594") do |t|
      b = t.fetch_first_by_tag("b")
      c = t.fetch_first_by_tag("c")
      if b && b.content
        if c && c.content && c.content.to_i > 1
          scorings << "#{b.content} (#{c.content})"
        else
          scorings << b.content
        end
      end
    end

    # Feeding 240$n workcatalog number from 690$a/$n and 383$b
    n240 = root.fetch_first_by_tag("240")
    existent = n240 ? n240.fetch_all_by_tag("n").map {|sf| sf.content rescue nil} : []
    each_by_tag("690") do |t|
      wv = t.fetch_first_by_tag("a")
      wvno = t.fetch_first_by_tag("n")
      content = "#{wv.content rescue nil} #{wvno.content rescue nil}"
      next if existent.include?(content)
      n240.add_at(MarcNode.new(@model, "n", content, nil), 0) if n240
    end
    each_by_tag("383") do |t|
      wvno = t.fetch_first_by_tag("b")
      content = "#{wvno.content rescue nil}"
      next if existent.include?(content)
      n240.add_at(MarcNode.new(@model, "n", content, nil), 0) rescue nil
    end

    # Adding digital object links to 500 with new records
    #TODO whe should drop the dublet entries in 500 with Digital Object Link prefix for older records
    if !parent_object.digital_objects.empty?# && parent_object.id >= 1001000000
      parent_object.digital_objects.each do |image|
        # FIXME we should use the domain name from application.rb instead
        path = image.attachment.path.gsub("/path/to/the/digital/objects/directory/", "http://muscat.rism.info/")
        content = "#{image.description + ': ' rescue nil}#{path}"
        n500 = MarcNode.new(@model, "500", "", "##")
        n500.add_at(MarcNode.new(@model, "a", content, nil), 0)
        root.children.insert(get_insert_position("500"), n500)
      end
    end
   
    if scorings.count > 0
      n594 = MarcNode.new(@model, "594", "", "##")
      n594.add_at(MarcNode.new(@model, "a", scorings.join(", "), nil), 0)
      root.children.insert(get_insert_position("594"), n594)
    end

    # First drop all internal remarks 
    by_tags("599").each {|t| t.destroy_yourself}
 
    entry = "#{parent_object.wf_audit rescue '[without indication]'}"
    n599 = MarcNode.new(@model, "599", "", nil)
    n599.add_at(MarcNode.new(@model, "b", entry, nil), 0)
    @root.add_at(n599, get_insert_position("599"))
   
    # Then add some if we include versions
    if versions
      versions.each do |v|
        author = v.whodunnit != nil ? "#{v.whodunnit}, " : ""
        entry = "#{author}#{v.created_at} (#{v.event})"
        n599 = MarcNode.new(@model, "599", "", nil)
        n599.add_at(MarcNode.new(@model, "a", entry, nil), 0)
        @root.add_at(n599, get_insert_position("599"))
      end
        
    end

    if holdings
      if parent_object.source_id
        parent_object = Source.find(parent_object.source_id)
      end
      parent_object.holdings.order(:lib_siglum).each do |holding|
        id = holding.id
        holding.marc.all_tags.each do |tag|
          tag.add_at(MarcNode.new(@model, "3", id, nil), 0)
          @root.add_at(tag, get_insert_position(tag.tag)) if tag.tag != "001"
        end
      end
    end

  end
    
  def set_record_type(rt)
    @record_type = rt
  end

end

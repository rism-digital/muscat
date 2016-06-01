class MarcSource < Marc
  
  # record_type mapping
  RECORD_TYPES = {
    :unspecified => 0,
    :collection => 1,
    :manuscript => 2,
    :print => 3,
    :manuscript_libretto => 4,
    :print_libretto => 5,
    :manuscript_theoretica => 6,
    :print_theoretica => 7,
    :convolutum => 8,
  }
  
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
    node = first_occurance("240", "a")
    standard_title = pretty_truncate(node.content, 50) if node 
   
    # try to get the description (240 m)
    node = first_occurance("240", "m")
    scoring = pretty_truncate(node.content, 50) if node
   
    node = first_occurance("240", "k")
    extract = pretty_truncate(node.content, 50) if node
    
    node = first_occurance("240", "o")
    arr = pretty_truncate(node.content, 50) if node
   
    if !standard_title
      if @record_type == RECORD_TYPES[:convolutum]
        standard_title = "[Colvolutum]"
      elsif @record_type == RECORD_TYPES[:collection]
        standard_title = "[Collection]"
      end
    end
    
    title = standard_title || "[Without title]" ## if title is unset and it is not collection

    std_title = [title, extract, arr, scoring].compact.join("; ")
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
        a_tag = tag.fetch_first_by_tag("a").content
        siglum = siglum == "" ? "#{a_tag}" : "#{siglum}, #{a_tag}"
      end
      #siglum = "[multiple copies]"
      ms_no = "[multiple copies]"
          
    elsif tags_852.length == 1 # single copy
      if node = first_occurance("852", "a")
        siglum = node.foreign_object.siglum
        siglum = "" if !siglum
      end
      if node = first_occurance("852", "p")
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

  # For holding records, set the condition and the urls (aliases)
  def get_ms_condition_and_urls
    ms_condition = "" 
    urls = ""
    image_urls = ""
    
    tag_852 = first_occurance( "852" )
    if tag_852
      q_tag = tag_852.fetch_first_by_tag("q")
      ms_condition = q_tag.content if q_tag
    
      url_tags = tag_852.fetch_all_by_tag("u")
      url_tags.each do |u|
        image_urls += "#{u.content}\n"
      end
      
      url_tags = tag_852.fetch_all_by_tag("z")
      url_tags.each do |u|
        urls += "#{u.content}\n"
      end
      
    end
    
    return [ms_condition.truncate(255), urls.truncate(128), image_urls.truncate(255)]
  end
  
  # Set miscallaneous values
  def get_miscellaneous_values

    language = "Unknown"
    date_from = nil
    date_to = nil

    if node = first_occurance("008")
      unless node.content.empty?
        language = LANGUAGES[marc_helper_get_008_language(node.content)] || "Unknown"
      end
    end
    
    if node = first_occurance("033", "a")
      if node && node.content
        date_from = marc_get_range(node.content, 0, 4) || nil
        date_to = marc_get_range(node.content, 4, 4) || nil
      end
    end

    # Force it to nil if 0, this used to work in the past
    date_from = nil if date_from.to_i == 0
    date_to = nil if date_to.to_i == 0
    
    return [language.truncate(16), date_from, date_to]

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
    elsif leader.match(/......d[dm].............../)
      rt = RECORD_TYPES[:manuscript]
    elsif leader.match(/......c[dm].............../)
      rt = RECORD_TYPES[:print]
    elsif leader.match(/......tm.............../)
      rt = RECORD_TYPES[:manuscript_libretto]
    elsif leader.match(/......am.............../)
      rt = RECORD_TYPES[:print_libretto]
    elsif leader.match(/......pm.............../)
      rt = RECORD_TYPES[:manuscript_theoretica] # we cannot make the distinction between ms and print
    elsif leader.match(/......pd.............../)
      rt = RECORD_TYPES[:convolutum]
    else
       puts "Unknown leader #{leader}"
    end
    
    return rt
  end
  
  def to_internal
    super

    # convert leader to record_type
    rt = match_leader
    
    # Drop leader


    # Move 130 to 240
    each_by_tag("130") do |t|

      node = t.deep_copy
      node.tag = "240"
      node.indicator = "10"
      node.sort_alphabetically
      root.children.insert(get_insert_position("240"), node)
      
      t.destroy_yourself
      
    end
    
    # Drop $2pe in 031, see #194
    each_by_tag("031") do |t|
      st = t.fetch_first_by_tag("2")
      if st && st.content && st.content != "pe"
        puts "Unknown 031 $2 value: #{st.content}"
      end
      st.destroy_yourself if st
    end
    
    each_by_tag("594") do |t|
      t.each_by_tag("a") do |st|
        st.destroy_yourself if st
      end
    end
    
    each_by_tag("691") do |t|
      t.each_by_tag("c") do |st|
        st.destroy_yourself if st
      end
    end
    
    each_by_tag("772") do |t|
      t.each_by_tag("t") do |st|
        st.destroy_yourself if st
      end
    end
    
    if rt
      @record_type = rt
    end
  end
  
  def to_external
    super
    
    # See #176
    # Step 1, rmake leader
    # collection, if we have prints only (......cc...............) or not (......dc...............)
    # manuscript and print, if it is part of a collection (......[cd]d...............) or not (......[cd]m...............)

    base_leader = "00000nXX#a2200000#u#4500"

    if @record_type == RECORD_TYPES[:collection]
      type = "cc"
      
      each_by_tag("772") do |t|
        w = t.fetch_first_by_tag("w")
        if w && w.content
          source = Source.find(w.content)
          type = "dc" if source.record_type != RECORD_TYPES[:print]
        else
          raise "Empty $w in 772"
        end
      end
      
      leader = base_leader.gsub("XX", type)
    elsif @record_type == RECORD_TYPES[:manuscript]
      type = "dm"
      type = "dd" if by_tags("773").count > 0
      leader = base_leader.gsub("XX", type)
    elsif @record_type == RECORD_TYPES[:print]
      type = "cm"
      type = "cd" if by_tags("773").count > 0
      leader = base_leader.gsub("XX", type)
    elsif @record_type == RECORD_TYPES[:manuscript_libretto]
      leader = base_leader.gsub("XX", "tm")
    elsif @record_type == RECORD_TYPES[:print_libretto]
      leader = base_leader.gsub("XX", "am")
    elsif @record_type == RECORD_TYPES[:manuscript_theoretica] # we cannot make the distinction between ms and print
      leader = base_leader.gsub("XX", "pm")
    elsif @record_type == RECORD_TYPES[:convolutum]
      leader = base_leader.gsub("XX", "pd")
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
    
  end
    
  def set_record_type(rt)
    @record_type = rt
  end
  
end

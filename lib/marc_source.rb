class MarcSource < Marc
  def initialize(source = nil)
    super("source", source)
  end
  
  # Get the std_title and std_title_d values
  def get_std_title  
    std_title = ""
    std_title_d = ""
    
    # try to get the title (130)
    node = first_occurance("130", "a")
    # get 240 if nothing or PSMD
    if !node || RISM::BASE == "pr"
      node = first_occurance("240", "a")
    end
    # get 245 if INVENTORIES
    if RISM::BASE == "in"
      node = first_occurance("245", "a")
    end
    standard_title = node.foreign_object if node 
   
    # we found one
    if standard_title
      # specific for inventories
      if RISM::BASE == "in"
        std_title = pretty_truncate(standard_title.title, 50)
        std_title_d = DictionaryOrder::normalize(std_title)
      else
        std_title = standard_title.title
        std_title_d = standard_title.title_d
      end
    # or not
    else
      if is_convolutum?
        std_title = "[Convolutum]"  
        std_title_d = '+'      
      elsif is_holding?
        std_title = "[Holding]"  
        std_title_d = '+' 
      else
        std_title = "[Collection]"
        std_title_d = '-' 
      end
    end
    
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
      end
      if node = first_occurance("852", "p")
        ms_no = node.content
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
    
    # Special quirk for a-1
    # Reprints not always have 245 set, so we copied the 245 from the parent
    # into the 246. Since only reprints have 246, we can safely copy it from
    # there so it shows the [previous entry:] tag.
    # Quirky because it will re-read the marc data
    if RISM::BASE == "a1"
      if node = first_occurance("246", "a")
        ms_title = node.content
      end
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
    
    # In a1 is only in 033
    if RISM::BASE == "a1"
      language = "Unknown"
      date_from = nil
      date_to = nil

      # Try to extract all the text from 260
      if node = first_occurance("260")
        tag = node.fetch_first_by_tag(:c)
        if tag && tag.content
          toks = tag.content.split(/(\d+)/)
          first = true
          toks.each do |tk|
            next if tk.to_i == 0
            
            if first          
              date_from = tk.to_i
              first = false
            else
              date_to = tk.to_i
            end
            
          end
        end
      end
      return [language, date_from, date_to]
      
    else
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
    
  end
  
  # Return if the MARC leader matches npd, i.e. convolutum
  def is_convolutum?
    return false unless get_leader.match(/^.....npd.*$/i)
    return true
  end

  # Return if the MARC leader matches nu, i.e. holding
  def is_holding?
    return false unless get_leader.match(/^.....nu.*$/i)
    return true
  end

end

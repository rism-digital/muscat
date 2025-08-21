class MarcInventoryItem < Marc
  def initialize(source = nil)
    super("inventory_item", source)
  end
  
  def get_composer
    composer = ""
    if node = first_occurance("100", "a")
      person = node.foreign_object
      composer = person.full_name
    end
    composer&.strip
  end

  def get_source_title
    ms_title = "[none]"  
    ms_title_field = "246"
    if node = first_occurance(ms_title_field, "a")
      ms_title = node.content
    end
    if node = first_occurance(ms_title_field, "b")
      ms_title += " #{node.content}" if node.content
    end
   
    ms_title.truncate(255)&.strip
  end

  # Standard title a' la source
  def get_std_title  
    node = first_occurance("240", "a")
    standard_title = node&.content&.truncate(50)
    standard_title = standard_title&.strip
    
    # try to get the description (240 m)
    # vl (2), vla, vlc
    node = first_occurance("240", "m")
    scoring = node.content.truncate(50) if node && node.content
    scoring = scoring.strip if scoring
   
    node = first_occurance("240", "k")
    extract = node.content.truncate(50) if node && node.content
    extract = extract.strip if extract
    
    node = first_occurance("240", "o")
    arr = node.content.truncate(50) if node && node.content
    arr = arr.strip if arr

    node = first_occurance("240", "r")
    key = node.content.truncate(50) if node && node.content
    key = arr.strip if arr
   
    title = (standard_title != nil || standard_title != "") ? standard_title : "[Without title]"

    desc = [extract, arr, scoring, key].compact.join("; ")
    desc = nil if desc.empty?
    
    # use join so the "-" is not placed if one of the two is missing
    std_title = [title, desc].compact.join(" - ")
    std_title&.strip
  end

end

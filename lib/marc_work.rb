class MarcWork < Marc
  def initialize(source = nil)
    super("work", source)
  end
  
  def get_title
    composer, title, scoring, number, key = ""
    if node = first_occurance("100", "a")
      composer = node.content.blank? ? "" : "#{node.content}:"
    end

    if node = first_occurance("130", "a")
      title = node.content.blank? ? " [without title]" : " #{node.content}"
    end

    if node = first_occurance("130", "r")
      key = node.content.blank? ? "" : " #{node.content}"
    end

    cat_no = get_catalogue

    return "#{composer}" + [title, key, cat_no].join("; ")
  end

  def get_opus
    node = first_occurance("383", "b")
    opus = node.content.truncate(50) if node && node.content
    opus = opus ? opus.strip : ""
  end

  def get_catalogue
    node = first_occurance("690", "a")
    cat_a = node.content.truncate(50) if node && node.content
    cat_a = cat_a.strip if cat_a
    
    node = first_occurance("690", "n")
    cat_n = node.content.truncate(50) if node && node.content
    cat_n = cat_n.strip if cat_n
   
    cat_no = "#{cat_a} #{cat_n}".strip
    cat_no = cat_no.empty? ? "" : cat_no
  end 

  def get_composer
    person = nil
    if node = first_occurance("100", "a")
      person = node.foreign_object
    end
    return person
  end

  def get_link_status
    status = 0
    each_by_tag("024") do |t|
      t.each_by_tag("2") do |t2|
        if t2 and t2.content
          case t2.content
          when "DNB"
            status |= 1
          when "BNF"
            status |= 2
          when "MBZ"
            status |= 4
          end
        end
      end
    end
    return status
  end

  def reset_to_new
    first_occurance("001").content = "__TEMP__"
  end

  # Make sure we do not use the default to_external
  def to_external(created_at = nil, updated_at = nil, versions = nil, holdings = false, deprecated_ids = true)
  end

end

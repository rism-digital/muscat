class MarcWork < Marc
  def initialize(source = nil)
    super("work", source)
  end
  
  def get_title
    composer, title, scoring, number, key = ""
    if node = first_occurance("100", "a")
      composer = node.content.blank? ? "" : "#{node.content}:"
    end
    if node = first_occurance("100", "t")
      title = node.content.blank? ? " [without title]" : " #{node.content}"
    end
    #if node = first_occurance("100", "n")
    #  number = node.content.blank? ? "" : " #{node.content}"
    #end
    if node = first_occurance("100", "r")
      key = node.content.blank? ? "" : " #{node.content}"
    end
    #if node = first_occurance("100", "m")
    #  scoring = node.content.blank? ? "" : "; #{node.content}"
    #end

    return "#{composer}#{title}#{key}"
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
    if node = first_occurance("100", "a")
      person = node.foreign_object
    end
    return person
  end



end

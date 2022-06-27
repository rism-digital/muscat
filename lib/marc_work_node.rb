class MarcWorkNode < Marc
  def initialize(source = nil)
    super("work_node", source)
  end
  
  def get_title
    title = "", scoring = "", number = "", key = ""
    tag100 = first_occurance("100")
    return "[unspecified]" if !tag100
    # title from $t
    if node = tag100.fetch_first_by_tag("t")
        title = node.content.blank? ? "[without title]" : "#{node.content}"
    end
    # scoring from repeated $m
    if node = tag100.fetch_first_by_tag("m")
        scoring = node.content.blank? ? "" : ", #{node.content}"
    end
    # number from repeated $n
    if node = tag100.fetch_first_by_tag("n")
        number = node.content.blank? ? "" : ", #{node.content}"
    end
    # key from $r
    if node = tag100.fetch_first_by_tag("r")
        key = node.content.blank? ? "" : " (#{node.content})"
    end

    return "#{title}#{scoring}#{number}#{key}"
  end

  def get_composer_name
    composer = "[unpecified]"
    if node = first_occurance("100", "a")
      composer = "#{node.content}" if !node.content.blank?
    end
    return composer
  end

  def get_composer
    if node = first_occurance("100", "a")
      person = node.foreign_object
    end
    return person
  end

end

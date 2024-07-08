class MarcWorkNode < Marc
  def initialize(source = nil, model = "work_node")
    super(model, source)
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

  def merge_person(person)
    tag100 = first_occurance("100")
    tag100.add_at(MarcNode.new("work_node", "0", person.id, nil), 0)
  end

  def to_external(created_at = nil, updated_at = nil, versions = nil, holdings = false, deprecated_ids = true)
    super(created_at, updated_at, nil, holdings)
    # nothing specific to do - this is used ony for deprecating works
  end
  
end

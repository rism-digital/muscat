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

  def to_external(updated_at = nil, versions = nil, holdings = false)
    # cataloguing agency
    _003_tag = first_occurance("003")
    if !_003_tag
      agency = MarcNode.new(@model, "003", RISM::AGENCY, "")
      @root.children.insert(get_insert_position("003"), agency)
    end
  
    if updated_at
      last_transcation = updated_at.strftime("%Y%m%d%H%M%S") + ".0"
      # 005 should not be there, if it is avoid duplicates
      _005_tag = first_occurance("005")
      if !_005_tag
        @root.children.insert(get_insert_position("003"),
            MarcNode.new(@model, "005", last_transcation, nil))
      end
    end
    by_tags("667").each {|t| t.destroy_yourself}
  end

end

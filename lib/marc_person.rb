class MarcPerson < Marc
  def initialize(source = nil)
    super("person", source)
  end

  def get_full_name_and_dates
    full_name = ""
    full_name_d = ""
    dates = nil

    if node = first_occurance("100", "a")
      if node.content
        full_name = node.content.truncate(128)
        full_name_d = node.content.downcase.truncate(128)
      end
    end
    
    if node = first_occurance("100", "d")
      if node.content
        dates = node.content.truncate(24).sub(/[ ,;\.]+$/, "")
      end
    end
    
    [full_name, full_name_d, dates]
  end
  
  def get_alternate_names_and_dates
    names = []
    dates = nil
    
    each_by_tag("400") do |t|
      t.fetch_all_by_tag("a").each do |tn|
        next if !(tn && tn.content)
        names << tn.content
      end
    end
    
    if node = first_occurance("400", "d")
      if node.content
        dates = node.content
      end
    end
    
    [names.join("\n"), dates]
  end
    
  def get_gender_birth_place_source_and_comments
    gender = 0
    birth_place = nil
    source = nil
    comments = nil

    if node = first_occurance("370", "a")
      if node.content
        birth_place = node.content.truncate(128)
      end
    end
    # OPTIMIZE Gender should be saved as string 
    if node = first_occurance("375", "a")
      if node.content
        gender = 1
      end
    end
    
    if node = first_occurance("670", "a")
      if node.content
        source = node.content.truncate(255)
      end
    end
    
    if node = first_occurance("680", "i")
      if node.content
        comments = node.content
      end
    end
    
    [gender, birth_place, source, comments]
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

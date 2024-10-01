class MarcPerson < Marc
  def initialize(source = nil)
    super("person", source)
  end

  def get_full_name_and_dates
    full_name = ""
    dates = nil

    if node = first_occurance("100", "a")
      if node.content
        full_name = node.content.truncate(128)
      end
    end
    
    if node = first_occurance("100", "d")
      if node.content
        dates = node.content.truncate(24)
      end
    end
    
    [full_name, dates]
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

  def get_gender_birth_place_and_source
    gender = 0
    birth_place = nil
    source = nil

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

    [gender, birth_place, source]
  end

  
  def to_external(created_at = nil, updated_at = nil, versions = nil, holdings = false, deprecated_ids = true)
    super(created_at, updated_at, versions)

    add_auth_leader()

    by_tags("667").each {|t| t.destroy_yourself}
  end
 
  
end

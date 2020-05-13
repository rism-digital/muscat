class MarcPerson < Marc
  def initialize(source = nil)
    super("person", source)
  end

  def get_full_name_and_dates
    composer = ""
    composer_d = ""
    dates = nil

    if node = first_occurance("100", "a")
      if node.content
        composer = node.content.truncate(128)
        composer_d = node.content.downcase.truncate(128)
      end
    end
    
    if node = first_occurance("100", "d")
      if node.content
        dates = node.content.truncate(24)
      end
    end
    
    [composer, composer_d, dates]
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
  
  
end

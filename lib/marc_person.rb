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
  
  def get_display_name
    # Person name as displayed in people lists and autocomplete fields
    display_name = ""

    if node = first_occurance("100", "a")
      display_name = node.content
    end

    if node = first_occurance("100", "c")
      display_name += " (#{node.content})"
    end

    if node = first_occurance("100", "d")
      display_name += " - #{node.content}"
    end

    display_name.truncate(256)
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
    
    new_leader = MarcNode.new("person", "000", "00000nz  a2200000nc 4500", "")
    @root.children.insert(get_insert_position("000"), new_leader)

    # Remove the 667...
    by_tags("667").each {|t| t.destroy_yourself}

    # and add just one counting the linked sources
    if get_id && !get_id.empty?
      parent_object = Person.find(get_id)
      source_size = parent_object.referring_sources.where(wf_stage: 1).size rescue 0
      if source_size > 0
        n667 = MarcNode.new(@model, "667", "", "##")
        n667.add_at(MarcNode.new(@model, "a", "Published sources: #{source_size}", nil), 0)
        root.children.insert(get_insert_position("667"), n667)
      end
    end

  end
 
  
end

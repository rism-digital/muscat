class MarcInstitution < Marc
  @@labels = EditorConfiguration.get_default_layout(Institution.new()).labels_config
  def initialize(source = nil)
    super("institution", source)
  end

  def get_full_name_and_place
    full_name = ""
    place = ""

    if node = first_occurance("110", "a")
      if node.content
        full_name = node.content
        if node = first_occurance("110", "b")
          full_name += " #{node.content}" if node.content
        end
        full_name = full_name.truncate(255)
      end
    end

    if node = first_occurance("110", "c")
      if node.content
        place = node.content
      end
    end
    [full_name&.strip, place&.strip]
  end

  def get_corporate_name_and_subordinate_unit
    corporate_name = ""
    subordinate_unit = ""

    if node = first_occurance("110", "a")
      corporate_name = node.content.truncate(255) if node.content
    end

    if node = first_occurance("110", "b")
      subordinate_unit = node.content.truncate(255) if node.content
    end
    [corporate_name&.strip, subordinate_unit&.strip]
  end

  def get_address_and_url
    address = ""
    url = ""

    if node = first_occurance("371", "a")
      if node.content
        address = node.content.truncate(128)
      end
    end

    if node = first_occurance("371", "u")
      if node.content
        url = node.content.truncate(24)
      end
    end
    [address&.strip, url&.strip]
  end

  def get_siglum
    if node = first_occurance("094", "a")
      if node.content
        node.content.truncate(32)&.strip
      end
    end
  end

  def to_external(created_at = nil, updated_at = nil, versions = nil, holdings = false, deprecated_ids = true)
    super(created_at, updated_at, versions)
    parent_object = Institution.find(get_id)
    
    new_leader = MarcNode.new("institution", "000", "00000nz  a2200000nc 4500", "")
    @root.children.insert(get_insert_position("000"), new_leader)

    by_tags("667").each {|t| t.destroy_yourself}

    source_size = parent_object.referring_sources.where(wf_stage: 1).size + parent_object.holdings.size rescue 0
    if source_size > 0
      n667 = MarcNode.new(@model, "667", "", "##")
      n667.add_at(MarcNode.new(@model, "a", "Published sources: #{source_size}", nil), 0)
      root.children.insert(get_insert_position("667"), n667)
    end

    #1590 move 094 to 024    
    #1668 Take in account institutions without siglum
    t094 = first_occurance("094")
    if t094
      new024 = t094.deep_copy
      new024.tag = "024"
      root.children.insert(get_insert_position("024"), new024)

      # Then copy over 094 $a to 110 $g
      siglum = first_occurance("094", "a")
      t110 = first_occurance("110")
      # make sure there is a 110, and we have a siglum
      if t110 && siglum && siglum.content

        # Remove eventual $g, should not happen but here we are
        # The one in 024 takes precedence
        t110.each_by_tag("g") {|t| t.destroy_yourself}

        t110.add_at(MarcNode.new(@model, "g", siglum.content, nil), 0)
        t110.sort_alphabetically
      end
      # remove the tag
      t094.destroy_yourself
    end

  end

  def marc_helper_get_country(value)
    return [ :en, :fr, :de, :it ].map{|i| I18n.t(@@labels[value]["label"], locale: i)} rescue nil
  end

end

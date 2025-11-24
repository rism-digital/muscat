class MarcPlace < Marc
  def initialize(source = nil)
    super("place", source)
  end

  def get_place_name
    self["151"]&.first["a"]&.first&.content
  end
  
  def get_place_country
    #self["370"]&.first["c"]&.first&.content

    self["370"]&.first&.[]("c")&.first&.content
  end

  def get_place_district
    #self["370"]&.first["f"]&.first&.content

    self["370"]&.first&.[]("f")&.first&.content
  end

  def get_tgn_id
    self["024"].each do |t|
      if t["2"]&.first&.content == "TGN"
        return t["a"]&.first&.content&.to_s
      end
    end
    ""
  end
  
  def to_external(created_at = nil, updated_at = nil, versions = nil, holdings = false, deprecated_ids = true)
    super(created_at, updated_at, versions)
    
    new_leader = MarcNode.new("place", "000", "00000nz  a2200000nc 4500", "")
    @root.children.insert(get_insert_position("000"), new_leader)

    # Remove the 667...
    by_tags("667").each {|t| t.destroy_yourself}

    # and add just one counting the linked sources
    if get_id && !get_id.empty?
      parent_object = Place.find(get_id)
      source_size = parent_object.referring_sources.where(wf_stage: 1).size rescue 0
      if source_size > 0
        n667 = MarcNode.new(@model, "667", "", "##")
        n667.add_at(MarcNode.new(@model, "a", "Published sources: #{source_size}", nil), 0)
        root.children.insert(get_insert_position("667"), n667)
      end
    end

  end
 
  
end

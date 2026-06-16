class MarcWork < Marc
  def initialize(source = nil)
    super("work", source)
  end
  
  def get_title
    composer = first_occurance("100", "a")&.content.to_s.strip
    title = first_occurance("130", "a")&.content.to_s.strip
    key = first_occurance("130", "r")&.content.to_s.strip
    cat_no = get_catalogue.to_s.strip

    scoring = first_occurance("130", "m")&.content.to_s.strip
    scoring = scoring.truncate(50) unless scoring.empty?

    main = "#{composer}: #{title}"
    main += ", #{scoring}" unless scoring.blank?

    extras = [key, cat_no].reject(&:blank?)

    [main, *extras].join("; ")
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
    cat_no = cat_no.empty? ? "" : cat_no&.strip
  end 

  def get_composer
    person = nil
    if node = first_occurance("100", "a")
      person = node.foreign_object
    end
    return person
  end

  def get_link_status
    status = 0
    each_by_tag("024") do |t|
      t.each_by_tag("2") do |t2|
        if t2 and t2.content
          case t2.content
          when "DNB"
            status |= 1
          when "BNF"
            status |= 2
          when "MBZ"
            status |= 4
          end
        end
      end
    end
    return status
  end

  def reset_to_new
    first_occurance("001").content = "__TEMP__"
  end

  # Make sure we do not use the default to_external
  def to_external(created_at = nil, updated_at = nil, versions = nil, holdings = false, deprecated_ids = true)
    super(created_at, updated_at, versions)
    
    new_leader = MarcNode.new("work", "000", "00000nz  a2200000nc 4500", "")
    @root.children.insert(get_insert_position("000"), new_leader)

     _to_external_031!(Work.find(get_id))
  end

end

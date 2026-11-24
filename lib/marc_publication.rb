class MarcPublication < Marc
  def initialize(source = nil)
    super("publication", source)
  end
  
  def get_author
    author = ""
    if node = first_occurance("100", "a")
      if node.content
        author = node.content.truncate(255)
      end
    end
    author&.strip
  end

  def get_name
    title = ""

    if node = first_occurance("210", "a")
      if node.content
        title = node.content.truncate(255)
      end
    end
    title&.strip
  end
  
  def get_title
    title = ""

    # Accept both 240 or 245 for title, prefer the later
    ["240", "245"].each do |tag|
      if node = first_occurance(tag, "a")
        title = node.content
        if node = first_occurance(tag, "b")
          title += " #{node.content}" if node.content
        end
      end
    end
    title.truncate(255)&.strip
  end
  
  def get_place_and_date
    place = ""
    date = ""

    if node = first_occurance("260", "a")
      if node.content
        place = node.content.truncate(255)
      end
    end
    
    if node = first_occurance("260", "c")
      if node.content
        date = node.content.truncate(24)
      end
    end
    [place&.strip, date&.strip]

  end

  def get_journal
    title = ""

    if node = first_occurance("760", "t")
      if node.content
        title = node.content.truncate(255)
      end
    end
    title&.strip
  end
  
  def reset_to_new
    first_occurance("001").content = "__TEMP__"
  end

  def to_external(created_at = nil, updated_at = nil, versions = nil, holdings = false, deprecated_ids = true)
    super(created_at, updated_at, versions)
    
    new_leader = MarcNode.new("publication", "000", "00000nz  a2200000nc 4500", "")
    @root.children.insert(get_insert_position("000"), new_leader)
  end

end

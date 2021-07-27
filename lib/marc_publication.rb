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
    author
  end

  def get_name
    title = ""

    if node = first_occurance("210", "a")
      if node.content
        title = node.content.truncate(255)
      end
    end
    title
  end
  
  def get_title
    title = ""

    if node = first_occurance("240", "a")
      if node.content
        title = node.content.truncate(255)
      end
    end
    title
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
    [place, date]

  end

  def get_revue_title
    title = ""

    if node = first_occurance("760", "t")
      if node.content
        title = node.content.truncate(255)
      end
    end
    title
  end
  
  def reset_to_new
    first_occurance("001").content = "__TEMP__"
  end



end

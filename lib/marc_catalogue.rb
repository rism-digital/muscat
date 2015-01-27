class MarcCatalogue < Marc
  def initialize(source = nil)
    super("catalogue", source)
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
  
  def get_description
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

end

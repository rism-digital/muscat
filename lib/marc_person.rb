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
  
end
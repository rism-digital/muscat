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
        composer = node.content
        composer_d = node.content.downcase
      end
    end
    
    if node = first_occurance("100", "d")
      if node.content
        dates = node.content
      end
    end
    
    [composer, composer_d, dates]
  end
  
end
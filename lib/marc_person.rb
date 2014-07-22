class MarcPerson < Marc
  def initialize(source = nil)
    super("person", source)
  end
  
  def get_full_name
    composer = ""
    composer_d = ""

    if node = first_occurance("100", "a")
      if node.content
        composer = node.content
        composer_d = node.content.downcase
      end
    end
    
    [composer, composer_d]
  end
  
end
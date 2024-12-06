class MarcInventoryItem < Marc
  def initialize(source = nil)
    super("inventory_item", source)
  end
  
  def get_composer
    composer = ""
    if node = first_occurance("100", "a")
      person = node.foreign_object
      composer = person.full_name
    end
    composer
  end

  def get_source_title
    ms_title = "[none]"  
    ms_title_field = "246"
    if node = first_occurance(ms_title_field, "a")
      ms_title = node.content
    end
    if node = first_occurance(ms_title_field, "b")
      ms_title += " #{node.content}" if node.content
    end
   
    ms_title.truncate(255)
  end

end

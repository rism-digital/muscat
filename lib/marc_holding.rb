class MarcHolding < Marc
  def initialize(source = nil)
    super("holding", source)
  end
  
  def get_lib_siglum
    title = ""

    if node = first_occurance("852", "a")
      if node.content
        title = node.content.truncate(255)
      end
    end
    title
  end
  
end

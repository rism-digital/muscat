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

  def description
    res = {}
    first_occurance("852").each do |t|
      if %w(a c q).include?(t.tag)
        res[t.tag]=t.content
      end
    end
    begin
      return "#{res['a']}#{" " + res['c'] if res['c']}#{" [" + res['q'] +"]" if res['q']}"
    rescue 
      return "HOLDING WITHOUT SIGLUM"
    end
  end
  
end

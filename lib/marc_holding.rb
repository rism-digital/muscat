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
    node = first_occurance("852")
    if node
      node.each do |t|
        if %w(a c q).include?(t.tag)
          res[t.tag] = t.content if t.content
        end
      end
    end
    if res.length > 0
      return "#{res['a']}#{" " + res['c'] if res['c']}#{" [" + res['q'] +"]" if res['q']}"
    else
      I18n.t(:holding_no_siglum)
    end
  end

end

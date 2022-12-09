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

  def get_shelf_mark
    m = ""

    if node = first_occurance("852", "c")
      if node.content
        m = node.content
      end
    end
    m
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

  def digital_object?
    node = first_occurance("856", "x")

    return false if !node || !node.content
    return true if node.content.start_with?("IIIF") || node.content.start_with?("Digitized")
    false

  end

end

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

  def get_siglum_and_shelf_mark
    siglum = "" 
    ms_no = ""
    if node = first_occurance("852", "a")
      siglum = node.foreign_object.siglum rescue siglum = ""
      siglum = "" if !siglum
    end
    if node = first_occurance("852", "c")
      ms_no = node.content if node.content
    end
    return [siglum.truncate(255), ms_no.truncate(255)]
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

  # returning a list with 
  def to_source_tags(group)
    config = MarcConfigCache.get_configuration("source")
    source_tags = config.each_data_tag {|e| e}
    material_tags = config.tags_with_subtag("8").collect.to_a
    res = []
    all_tags.each do |tag|
      next unless source_tags.include?(tag.tag)
      if material_tags.include?(tag.tag) 
        if !tag.fetch_first_by_tag('8')
          tag.add(MarcNode.new(Holding, "8", ("%02d" % group), nil))
          res << tag.deep_copy
        else
          res << tag.deep_copy
        end
      else
        res << tag.deep_copy
      end
    end
    return res
  end

end

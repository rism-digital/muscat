class MarcWorkNode < Marc
  def initialize(source = nil, model = "work_node")
    super(model, source)
  end
  
  def get_title
    title = ""
    tag100 = first_occurance("100")
    return "[unspecified]" if !tag100
    # title from $t
    if node = tag100.fetch_first_by_tag("t")
        title = node.content.blank? ? "[without title]" : "#{node.content}"
    end

    #1662, emulate the GND title
    if node = tag100.fetch_first_by_tag("p")
      title = node.content.blank? ? title : "#{title}. #{node.content}"
    end

    if node = tag100.fetch_first_by_tag("n")
      title = node.content.blank? ? title : "#{title}; #{node.content}"
    end

    if node = tag100.fetch_first_by_tag("m")
      title = node.content.blank? ? title : "#{title}; #{node.content}"
    end

    return title.truncate(255)
  end

  def get_ext_nr
    tag = first_occurance("024")
    a = tag&.fetch_first_by_tag("a")&.content
    two = tag&.fetch_first_by_tag("2")&.content

    [a, two]
  end

  def get_composer_name
    composer = "[unpecified]"
    if node = first_occurance("100", "a")
      composer = "#{node.content}" if !node.content.blank?
    end
    return composer.truncate(255)
  end

  def get_composer
    if node = first_occurance("100", "a")
      person = node.foreign_object
    end
    return person
  end

  def merge_person(person)
    tag100 = first_occurance("100")
    tag100.add_at(MarcNode.new("work_node", "0", person.id, nil), 0)
  end

  def to_internal

    un_gnd("100", "t")
    un_gnd("400", "t")
    un_gnd("500", "t")

  end

  def to_external(created_at = nil, updated_at = nil, versions = nil, holdings = false, deprecated_ids = true)
    super(created_at, updated_at, nil, holdings)
    # nothing specific to do - this is used ony for deprecating works
  end
  
private

  def unwrap_and_mark(line)
    # Find:  U+0098 <article> U+009C <spaces> <next word>
    # Make:  <article> <spaces> @<next word>
    line.gsub(/\u{0098}(\p{L}[\p{L}’']*)\u{009C}(\s*)(?=\p{L})/u) do
      "#{$1}#{$2}@"
    end
  end

  def un_gnd(tag, subtag)
    self[tag].each do |t|
      t[subtag].each do |tt|
        tt.content = unwrap_and_mark(tt.content) if tt && tt.content
      end
    end
  end

end

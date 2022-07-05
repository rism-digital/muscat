class MarcWorkNode < Marc
  def initialize(source = nil, model = "work_node")
    super(model, source)
    ap model
    @gnd_person_id = nil
  end
  
  def get_title
    title = "", scoring = "", number = "", key = ""
    tag100 = first_occurance("100")
    return "[unspecified]" if !tag100
    # title from $t
    if node = tag100.fetch_first_by_tag("t")
        title = node.content.blank? ? "[without title]" : "#{node.content}"
    end
    # scoring from repeated $m
    if node = tag100.fetch_first_by_tag("m")
        scoring = node.content.blank? ? "" : ", #{node.content}"
    end
    # number from repeated $n
    if node = tag100.fetch_first_by_tag("n")
        number = node.content.blank? ? "" : ", #{node.content}"
    end
    # key from $r
    if node = tag100.fetch_first_by_tag("r")
        key = node.content.blank? ? "" : " (#{node.content})"
    end

    return "#{title}#{scoring}#{number}#{key}"
  end

  def get_composer_name
    composer = "[unpecified]"
    if node = first_occurance("100", "a")
      composer = "#{node.content}" if !node.content.blank?
    end
    return composer
  end

  def get_composer
    if node = first_occurance("100", "a")
      person = node.foreign_object
    end
    return person
  end

  def to_internal

    # replace "gnd" with "DNB" in $2
    node = first_occurance("024", "2")
    node.content = "DNB" if node && node.content
    # adjust tag 100
    tag100 = first_occurance("100")
    if tag100
        # move $p to $n
        tag100.each_by_tag("p") do |p|
            p.tag = "n"
        end
        # merge all $m into one
        m_subtags = tag100.fetch_all_by_tag("m")
        m_subtags.drop(1).each do |m_subtag|
            m_subtags[0].content += ", #{m_subtag.content}" if m_subtag.content
            m_subtag.destroy_yourself
        end
        # merge all $n into one
        n_subtags = tag100.fetch_all_by_tag("n")
        n_subtags.drop(1).each do |n_subtag|
            n_subtags[0].content += " #{n_subtag.content}" if n_subtag.content
            n_subtag.destroy_yourself
        end
    end

    # search for the corresponding composer in Muscat and set the 100 $0 accordingly
    person = nil
    tag500 = nil
    # first look for the 500 with $4 == kom1 in the GND record
    each_by_tag("500") do |tag|
        tag.each_by_tag("4") do |t4|
            if t4.content and t4.content == "kom1"
                tag500 = tag
                break
            end
        end
    end
    # get the $0 subfield with the gnd uri
    if tag500
        tag500.each_by_tag("0") do |t0|
            if t0.content and t0.content.start_with?("https://d-nb.info/gnd/")
                id = t0.content.gsub(/https:\/\/d-nb.info\/gnd\//, "")
                id = "DNB:#{id}"
                # retrieve the person pointing to it in Muscat (if any)
                #person = find_person(id)
                @gnd_person_id = id
                break
            end
        end
    end

    # remove all the 500 because they are not preserved in the WorkNode
    by_tags("500").each {|t| t.destroy_yourself}
  end

  def get_gnd_person_id
    @gnd_person_id
  end

  def merge_person(person)
    tag100 = first_occurance("100")
    tag100.add_at(MarcNode.new("work_node", "0", person.id, nil), 0)
  end

end

module Template

  # returns a list with all tags of a specific template
  def template_tags(record_type)
    s = Source.new(record_type: record_type)
    e = EditorConfiguration.get_default_layout(s)
    marc_tags = e.layout_tags
    excluded_tags = e.excluded_tags_for_record_type(s)
    return marc_tags - excluded_tags
  end

  # return difference between existing tags and tags of the new template
  def template_difference(rt)
    return marc.all_tags.map{|e| e.tag}.uniq - template_tags(rt).uniq
  end

  # create a holding record if the new template has no 852
  def create_holding
    puts "create holding record"
  end

  def move_tags(rt)
    omitted_tags = template_difference(rt)
    if omitted_tags.include?('852')
      create_holding
    end
  end

  def tag_rate
    ((marc.all_tags.map{|e| e.tag}.uniq.size.to_f / (template_tags(record_type).uniq.size.to_f * 100)) * 100).round(2)
  end
  
end

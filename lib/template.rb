# Basic module to change the template of a record
module Template

  # should return a hash with all allowed changes between templates 
  # TODO
  def allowed_templates
    puts "should be in editor configration"
  end

  # returns a list with all tags of a specific template
  def template_tags(record_type)
    s = Source.new(record_type: record_type)
    e = EditorConfiguration.get_default_layout(s)
    marc_tags = e.layout_tags
    excluded_tags = e.excluded_tags_for_record_type(s)
    return marc_tags - excluded_tags
  end

  # returns a list with differences between two templates
  def difference(rt1, rt2)
    return template_tags(rt1) - template_tags(rt2)
  end

  # return difference between existing tags and tags of the new template
  def template_difference(rt)
    return marc.all_tags.map{|e| e.tag}.uniq - template_tags(rt).uniq
  end

  # creates a holding record if the new template has no 852
  def create_holding
    marc.by_tags("852").each do |t|
      holding = Holding.new
      new_marc = MarcHolding.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/holding/default.marc"))
      new_marc.load_source false
      new_marc.each_by_tag("852") {|t2| t2.destroy_yourself}
      new_852 = t.deep_copy
      new_marc.root.children.insert(new_marc.get_insert_position("852"), new_852)
      new_marc.suppress_scaffold_links
      new_marc.import
      holding.marc = new_marc
      holding.source = self
      holding.suppress_reindex
      begin
        holding.save
      rescue => e
        $stderr.puts"SplitHoldingRecords could not save holding record for #{source.id}"
        $stderr.puts e.message.blue
        next
      end
      t.destroy_yourself
    end
  end

  # Move a holding record back to the parent
  # needs high caution
  # TODO
  def move_holding_to_852
  end

  # In case there is no target tag, the tag should be traversed to 599$ as raw string
  def backup_tag(tag)
    marc.by_tags(tag).each do |t|
      new_599 = MarcNode.new(Source, "599", "", "4#")
      ip = marc.get_insert_position("599")
      new_599.add(MarcNode.new(Source, "a", "#{t.to_s.strip}", nil))
      new_599.sort_alphabetically
      marc.root.children.insert(ip, new_599)
      t.destroy_yourself
    end
  end

  # Restore a backup tag from 599; checks target template tags before
  def restore_tags(rt)
    tags = template_tags(rt) 
    marc.by_tags("599").each do |t|
      new_content = t.fetch_first_by_tag("a").content
      if new_content =~ /=[0-9]{3}\s{2}/
        tag, content = new_content.split("  ")
        unless tags.include?(tag[1..4])
          next 
        else
          marc.parse_marc21(tag[1..4], content)
          t.destroy_yourself
        end
      end
    end
    self.save
  end

  # Moving tags which are not part of the target template to a holding or to 599 as temp storage
  def change_template_to(rt)
    template_difference(rt).each do |e|
      if e == '852'
        create_holding
      else
        backup_tag(e)
      end
    end
    restore_tags(rt)

    #self.restore_tags
    self.record_type = rt
    self.save
  end

  # Easy method to calculate the percentage of used tags of a template
  def tag_rate
    marc.load_source false
    ((marc.all_tags.map{|e| e.tag}.uniq.size.to_f / (template_tags(record_type).uniq.size.to_f * 100)) * 100).round(2)
  end
  
end

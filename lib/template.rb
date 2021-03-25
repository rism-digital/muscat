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
    new_marc = MarcSource.new
    new_marc.load_source false
    return new_marc.all_tags.map{|e| e.tag}.uniq - template_tags(rt).uniq
  end

  # creates a holding record if the new template has no 852
  def create_holding
    marc.by_tags("852").each do |t|
      holding = Holding.new
      new_marc = MarcHolding.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/holding/default.marc")))
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

  # Move a holding record back to the parent with 852
  # TODO move other fields to parent if a holding has more than 852
  def move_holding_to_852
    holdings.each do |holding|
      new_852 = holding.marc.first_occurance("852").deep_copy
      marc.root.add_at(new_852, marc.get_insert_position("852") )
      holding.destroy
    end
  end

  # Restore tags from previous template in versions
  def restore_tags(rt)
    restore_version = nil
    latest_versions = self.versions.order(created_at: :desc)
    latest_versions.each do |v|
      s = v.reify
      if s.record_type == rt
        restore_version = v.reify
        break
      end
    end
    if restore_version
      restore_version.template_difference(self.record_type).each do |tag|
        next if self.marc.has_tag?(tag)
        restore_version.marc.by_tags(tag).each do |t|
          new_tag = t.deep_copy
          marc.root.add_at(new_tag, marc.get_insert_position(tag) )
        end
        if tag == "852" && marc.has_tag?("852") && holdings.first
          holdings.first.destroy
        end
      end
    end
    if !marc.has_tag?("852") && holdings.first && template_tags(rt).include?("852")
      move_holding_to_852
    end
  end

  # Change source template to new record_type
  def change_template_to(rt)
    return if rt == self.record_type
    self.paper_trail.save_with_version if versions.empty?
    template_difference(rt).each do |e|
      if e == '852'
        create_holding
      else
        marc.by_tags(e).each do |t|
          t.destroy_yourself
        end
      end
    end
    restore_tags(rt)
    self.record_type = rt
    self.save
  end

  # Easy method to calculate the percentage of used tags of a template
  def tag_rate
    marc.load_source false
    ((marc.all_tags.map{|e| e.tag}.uniq.size.to_f / (template_tags(record_type).uniq.size.to_f * 100)) * 100).round(2)
  end
  
end

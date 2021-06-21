# Module to change the template of a record
module Template

  # returning a list with general accepted changes
  def self.allowed
    templates = MarcSource::RECORD_TYPES.to_a.select{|k,v| k if v!=0}.map{|k,v| ["#{I18n.t('record_types.' + k.to_s)}",v]}.sort
    allowed_templates = [1,2,3,4,5,6,7,8,9,10]
    return templates.filter{|e| allowed_templates.include?e[1]}
  end

  # returning a list with all allowed changes between templates 
  def allowed_changes
    allowed = [1,2,3,4,5,6,7,8,10]
    if allowed.delete(self.record_type)
      return allowed
    else
      return []
    end
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
  # TODO deprecated?
  def difference(rt1, rt2)
    return template_tags(rt1) - template_tags(rt2)
  end

  # return difference between existing tags and tags of the new template
  # TODO use for checks
  def template_difference(rt)    
    tags = marc.all_tags.collect.to_a.uniq
    return tags - template_tags(rt).uniq
  end

  # creates a holding record if the new template has no 852
  # TODO only if ther is 1 holding?
  def create_holding(group)
    holding = Holding.new
    new_marc = MarcHolding.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/holding/default.marc")))
    new_marc.load_source false
    marc.to_holding(group).each do |tag|
      # FIXME should 593 really be mandatory with prints?
      unless tag.tag == "593"
        marc.each_by_tag(tag.tag) {|t| t.destroy_yourself}
        new_marc.root.children.insert(new_marc.get_insert_position(tag.tag), tag)
      end
    end
    # add 588 node
    new_marc.suppress_scaffold_links
    new_marc.import
    holding.marc = new_marc
    holding.source = self
    n588 = MarcNode.new("source", "588", "", "##")
    n588.add_at(MarcNode.new("source", "a", holding.marc.get_siglum_and_shelf_mark.join(" "), nil), 0)
    marc.root.children.insert(marc.get_insert_position("588"), n588)
    holding.suppress_reindex
    begin
      holding.save
    rescue => e
      $stderr.puts"SplitHoldingRecords could not save holding record for #{source.id}"
      $stderr.puts e.message.blue
    end
  end

  # create holdings from material
  # TODO only for material group 1?
  def holdings_to_material
    # get count of material
    last_material_group = marc.all_values_for_tags_with_subtag("300", "8").sort.last.to_i
    holdings.each do |holding|
      tags = holding.marc.to_source_tags(last_material_group + 1)
      tags.each do |tag|
        if tag.tag == "852"
          if !marc.has_tag?("852")
            marc.root.add_at(tag, marc.get_insert_position(tag.tag) )
          else
            next
          end
        else
          marc.root.add_at(tag, marc.get_insert_position(tag.tag) )
        end
      end
      holding.destroy
    end
    marc.each_by_tag("588") do |tag| tag.destroy_yourself end
  end

  # Restore tags from previous template in versions
  # DEPRECATED
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
    holdings_to_material
  end

  # Change source template to new record_type
  def change_template_to(rt)
    return if rt == self.record_type
    return unless allowed_changes.include?(rt)
    self.paper_trail.save_with_version if versions.empty?
    if holdings.empty? && MarcSource.is_edition?(rt)
      create_holding(1)
    elsif !holdings.empty? && !MarcSource.is_edition?(rt)
      holdings_to_material
    end
    self.record_type = rt
    self.save
  end

  # Easy method to calculate the percentage of used tags of a template
  def tag_rate
    marc.load_source false
    ((marc.all_tags.map{|e| e.tag}.uniq.size.to_f / (template_tags(record_type).uniq.size.to_f * 100)) * 100).round(2)
  end
  
end

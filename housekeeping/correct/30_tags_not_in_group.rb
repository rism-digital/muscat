## but should be in a group!

u = {}

Source.all.each do |s|
	group = "edit_material"
	@editor_profile = EditorConfiguration.get_default_layout s
	tag_names = @editor_profile.layout_tag_names_for_group(s, group)
	
	subfield = @editor_profile.layout_config["groups"][group]["subfield_grouping"]
	
	tags_with_no_subfield = s.marc.by_tags_with_subtag(tag_names, subfield, "")


	tags_with_no_subfield = tags_with_no_subfield.select{ |t| !@editor_profile.layout_tags_not_in_subfield_grouping.include? t.tag }
	
	puts "#{s.id} -  #{s.get_record_type}" if tags_with_no_subfield.count > 0

	tags_with_no_subfield.each do |tn|
		puts "\t#{tn}"
	end

end

Source.all.each do |s|	

	@editor_profile = EditorConfiguration.get_default_layout s

	tag_names = Array.new
		@editor_profile.each_tag_not_in_layout s do |tag|
		tag_names << tag
	end
	
	rt = I18n.t('record_types.' + s.get_record_type.to_s)

	if tag_names.count > 1
		puts "#{s.id} #{rt} #{tag_names.to_s}"
	end

end

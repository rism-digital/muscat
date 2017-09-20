Source.where("record_type = 1 and not composer = ''").each do |s|
	s.child_sources.each do |cs|
		puts cs.id if !cs.composer.empty?
	end
end
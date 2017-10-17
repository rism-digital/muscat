pb = ProgressBar.new(Source.where("record_type = 1 and composer = ''").count)
Source.where("record_type = 1 and composer = ''").each do |s|
	composers = []
	s.child_sources.each do |cs|
		composers << cs.composer
	end
	
	unique =  composers.sort.uniq
	if unique.count == 1
		if !unique[0].empty?
			#puts "#{s.id} #{unique[0]}"
			
			marc = s.marc
			marc.load_source
			s.paper_trail_event = "Add 100"
			
			pe = Person.where(full_name: unique[0]).first
			
			new_tag = MarcNode.new("source", "100", "", "1#")
			#new_tag.add_at(MarcNode.new("source", "a", unique[0], nil), 0)
			new_tag.add_at(MarcNode.new("source", "0", pe.id, nil), 0)
			new_tag.sort_alphabetically
			new_tag.foreign_object = pe
			marc.root.children.insert(marc.get_insert_position("100"), new_tag)

			
			s.save
			
			s2 = Source.find(s)
			s2.save
			
		end
	end
	pb.increment!
end


## Do it for normal records too
pb = ProgressBar.new(Source.where("record_type = 2 and composer = ''").count)
Source.where("record_type = 2 and composer = ''").each do |s|

	marc = s.marc
	marc.load_source
	s.paper_trail_event = "Add Anonymus"
	
	#puts s.id
	
	new_tag = MarcNode.new("source", "100", "", "1#")
	#new_tag.add_at(MarcNode.new("source", "a", unique[0], nil), 0)
	new_tag.add_at(MarcNode.new("source", "0", 30004985, nil), 0)
	new_tag.sort_alphabetically
	marc.root.children.insert(marc.get_insert_position("100"), new_tag)
	
	s.save

	s2 = Source.find(s)
	s2.save
	
	pb.increment!

end
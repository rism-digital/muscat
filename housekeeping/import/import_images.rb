doc = Nokogiri::XML.parse(File.open('digital_objects.xml'))

doc.xpath('/images/image').each do |i|

	f = i.xpath('file').collect.first
	next if !f
	
	title = i.xpath('title').collect.first.content

	sources = []
	i.xpath('sources/rism_id').collect do |s|
		if s.content && !s.content.empty?
			sources << s.content
		end
	end
	
	people = []
	i.xpath('person/isn').collect do |s|
		if s.content && !s.content.empty?
			people << s.content
		end
	end
	
	if sources.length > 0 || people.length > 0

		path = "/root/inages/#{f.content}"
		puts "Processing #{path} for #{sources.to_s} and #{people.to_s}"
		if !File.exists?(path)
			puts "Could not find #{path}"
			next
		end
    
		obj = DigitalObject.create(:attachment => File.open(path, 'rb'), :description => title)
		
		user = User.find(1)
		
		sources.each do |src|
			begin
				s = Source.find(src)
			rescue ActiveRecord::RecordNotFound => e
				puts "could not find source #{src}"
				next
			end
			
		    dol = DigitalObjectLink.create(object_link_type: "Source", object_link_id: src.to_i,
		                                  user: s.user, digital_object_id: obj.id)
		end
		
		people.each do |pr|
			begin
				Person.find(pr)
			rescue ActiveRecord::RecordNotFound => e
				puts "could not find person #{p}"
				next
			end
			
		    dol = DigitalObjectLink.create(object_link_type: "Person", object_link_id: pr.to_i,
		                                  user: user, digital_object_id: obj.id)
		end
	end
end

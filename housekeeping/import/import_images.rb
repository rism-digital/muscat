doc = Nokogiri::XML.parse(File.open('rism_mm.xml'))

doc.xpath('/images/image').each do |i|

	f = i.xpath('file').collect.first
	next if !f
	
	title = i.xpath('title').collect.first.content

	src = nil
	i.xpath('sources/rism_id').collect do |s|
		if s.content && !s.content.empty?
			src = s.content
			break	
		end
	end
	
	if src
		begin
			Source.find(src)
		rescue ActiveRecord::RecordNotFound => e
			puts "could not find #{src}"
			next
		end
		path = "/root/images/#{f.content}"
		puts "Processing #{path} for #{src}"
		next if !File.exists?(path)
    
		obj = DigitalObject.create(:attachment => File.open(path, 'rb'), :description => title)
    
    dol = DigitalObjectLink.create(object_link_type: "Source", object_link_id: src.to_i,
                                  user: 1, digital_object_id: obj.id)
	end
end

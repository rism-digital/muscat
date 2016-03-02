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
		DigitalObject.create(:source_id => src.to_i, :attachment => File.open(path, 'rb'), :description => title)
	end
end

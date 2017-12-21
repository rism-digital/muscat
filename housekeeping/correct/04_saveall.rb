require 'progress_bar'

Source.paper_trail.disable

pb = ProgressBar.new(Source.all.count)

Source.find_each do |s|
  
	pb.increment!
	
	s.suppress_update_77x
	s.suppress_update_count
	s.suppress_reindex
	begin
		s.save!
	rescue => e
		puts "Could not save source #{s.id}"
		puts e.exception
	end
end
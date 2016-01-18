require 'progress_bar'

pb = ProgressBar.new(Source.all.count)

Source.all.each do |sa|
  
  s = Source.find(sa.id)
  
  s.record_type = s.marc.to_internal
  
	s.suppress_update_77x
	s.suppress_update_count
  s.suppress_reindex
  
  begin
    s.save
  rescue => e
    puts e.message
  end
  
  pb.increment!
  
end
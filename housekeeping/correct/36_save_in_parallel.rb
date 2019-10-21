@parallel_jobs = 10
@all_src = Source.all.count
@limit = @all_src / @parallel_jobs

begin_time = Time.now
  
results = Parallel.map(0..@parallel_jobs, in_processes: @parallel_jobs, progress: "Saving sources") do |jobid|
  offset = @limit * jobid

  Source.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
    s = Source.find(sid.id)
    
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
end

end_time = Time.now
message = "Source saving started at #{begin_time.to_s}, (#{end_time - begin_time} seconds run time)"
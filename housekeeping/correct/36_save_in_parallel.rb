@parallel_jobs = 10
@all_src = Source.where("id > 400000000 and id < 420000000").count
@limit = @all_src / @parallel_jobs

begin_time = Time.now
  
results = Parallel.map(0..@parallel_jobs, in_processes: @parallel_jobs, progress: "Saving sources") do |jobid|
  offset = @limit * jobid

  Source.where("id > 400000000 and id < 420000000").order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
	puts sid.id
    s = Source.find(sid.id)
    
	s.marc.load_source(false)
	s.marc.import
	
	s.suppress_reindex
	s.suppress_update_77x
	s.suppress_update_count

	s.save
    s = nil
  end
end

end_time = Time.now
message = "Source saving started at #{begin_time.to_s}, (#{end_time - begin_time} seconds run time)"
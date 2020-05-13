@parallel_jobs = 10
@all_src = Source.all.count
@limit = @all_src / @parallel_jobs

begin_time = Time.now
  
results = Parallel.map(0..@parallel_jobs, in_processes: @parallel_jobs, progress: "Loading Sources") do |jobid|
  offset = @limit * jobid
    r = []

  Source.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
    s = Source.find(sid.id)
    
    s.marc.load_source false

    s.marc.each_by_tag("031") do |t|
  
      t.fetch_all_by_tag("o").each do |tn|
        found = false
        next if !(tn && tn.content)
        puts "#{s.id} SOURCE" if tn.content.to_s == "0"        
      end

    end
    
  end
  r
end

ap results

end_time = Time.now
message = "Started at #{begin_time.to_s}, (#{end_time - begin_time} seconds run time)"
@parallel_jobs = 10
@all_src = Source.all.count
@limit = @all_src / @parallel_jobs

begin_time = Time.now
  
results = Parallel.map(0..@parallel_jobs, in_processes: @parallel_jobs, progress: "Saving sources") do |jobid|
  offset = @limit * jobid

  Source.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
    s = Source.find(sid.id)
    
    grp_ids = []
    
    s.marc.each_by_tag("593") do |t|
      t.fetch_all_by_tag("8").each do |tn|

        next if !(tn && tn.content)
        grp_ids << tn.content

      end
    end
    
    if grp_ids.length - grp_ids.uniq.length > 0
      $stderr.puts s.id
    end
    
  end
end

end_time = Time.now
message = "Started at #{begin_time.to_s}, (#{end_time - begin_time} seconds run time)"
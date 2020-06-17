@parallel_jobs = 10
@all_src = Source.all.count
@limit = @all_src / @parallel_jobs

begin_time = Time.now
#in_processes: @parallel_jobs
results = Parallel.map(0..@parallel_jobs, in_processes: @parallel_jobs, progress: "Loading Sources") do |jobid|
  ActiveRecord::Base.connection.reconnect!
  offset = @limit * jobid
    r = []

    s = Source.first

  Source.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
    ActiveRecord::Base.connection.reconnect!
    s = Source.find(sid.id)
    
    #puts s.id if s.siglum_matches?("CH-")
    next if !s.siglum_matches?("CH-")

    s.marc.load_source false
    #puts "ciao"
    #puts s.id
    

    if s.marc.root.fetch_all_by_tag("650").count == 0

      s.marc.each_by_tag("240") do |t|
        #t.fetch_all_by_tag("a").each do |tn|
        #end
        a240 = t.fetch_first_by_tag("a").content rescue a240 = "n.a."
      end
      
      s.marc.each_by_tag("245") do |t|
        #t.fetch_all_by_tag("a").each do |tn|
        #end
        a245 = t.fetch_first_by_tag("a").content rescue a245 = "n.a."
      end

      puts "#{s.id}\t#{a240}\t#{a245}"

    end

  end
  r
end

ap results

end_time = Time.now
message = "Started at #{begin_time.to_s}, (#{end_time - begin_time} seconds run time)"
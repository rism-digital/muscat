
File.open("rism.ttl", 'w') do |writer|

    @parallel_jobs = 10
    @all_src = Source.all.count
    @limit = @all_src / @parallel_jobs

    results = Parallel.map(0..@parallel_jobs, in_processes: @parallel_jobs, progress: "Saving sources") do |jobid|
        offset = @limit * jobid

        Source.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
            s = Source.find(sid.id)
            s.marc.load_source false
            writer << RdfSourceExport.new(s).to_ttl
            s = nil
        end #batch.each
    end #batch
end #writer
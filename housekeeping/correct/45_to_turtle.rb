
File.open("rism.ttl", 'w') do |writer|

    @parallel_jobs = 10
    @all_src = Source.all.count
    @limit = @all_src / @parallel_jobs

    results = Parallel.map(0..@parallel_jobs, in_processes: @parallel_jobs, progress: "Saving sources") do |jobid|
        offset = @limit * jobid

        Source.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
            s = Source.find(sid.id)

            RdfSourceExport.new(s).to_ttl

        end #batch.each
    end #batch
end #writer

puts "Source exporting started at #{begin_time.to_s}, (#{Time.now - begin_time} seconds run time)"
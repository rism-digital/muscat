Pathname.new(REINDEX_PIDFILE).write(Process.pid)

@parallel_jobs = 10
@all_src = Source.all.count
@limit = @all_src / @parallel_jobs

begin_time = Time.now
  
results = Parallel.map(0..@parallel_jobs - 1, in_processes: @parallel_jobs, progress: "Reindexing sources") do |jobid|
    offset = @limit * jobid
    count = 0
    e_count = 0
    Source.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
        s = Source.find(sid.id)
    
        begin
            Sunspot.index s
            count += 1
        rescue => e
            puts "Could not load #{sid.id}: #{e.exception}"
            e_count += 1
        end
    end
    [count, e_count]
end

end_time = Time.now
puts "Reindex saving started at #{begin_time.to_s}, ended at: #{end_time.to_s}"
puts "(#{end_time - begin_time} seconds run time)"
puts "Results are: #{results.to_s}"

indexed_sources = results.inject(0){|n, item| n += item[0]}
error_sources = results.inject(0){|n, item| n += item[1]}

puts "Indexed sources: #{indexed_sources}, Unloadable sources: #{error_sources}"

Pathname.delete(REINDEX_PIDFILE)
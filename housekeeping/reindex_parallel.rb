Pathname.new(REINDEX_PIDFILE).write(Process.pid)

@parallel_jobs = 10
@source_count = Source.all.count
@sources_per_chunk = @source_count / @parallel_jobs
@reminder = @source_count - (@sources_per_chunk * @parallel_jobs)

begin_time = Time.now
puts "Reindexing #{@source_count} sources in #{@parallel_jobs} processes with a reminder of #{@reminder} (#{@sources_per_chunk} per chunk)"

results = Parallel.map(0..@parallel_jobs - 1, in_processes: @parallel_jobs) do |jobid|
    offset = @sources_per_chunk * jobid

    limit = @sources_per_chunk
    # On the last job add the reminder
    limit += @reminder if jobid == @parallel_jobs - 1

    current_limit = 0
    e_count = 0
    while current_limit < limit
        begin
            Sunspot.index(Source.order(:id).limit(1000).offset(offset + current_limit).select(&:force_marc_load?))
        rescue => e
            puts "OOPS: #{e.exception}"
            e_count += 1
        end
        current_limit += 1000
    end
    [current_limit, e_count]

=begin
    count = 0
    e_count = 0
    Source.order(:id).limit(limit).offset(offset).select(:id).each do |sid|
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
=end
end

end_time = Time.now
puts "Reindex started at #{begin_time.to_s}, ended at: #{end_time.to_s}"
puts "(#{end_time - begin_time} seconds run time)"
puts "Results are: #{results.to_s}"

indexed_sources = results.inject(0){|n, item| n += item[0]}
error_sources = results.inject(0){|n, item| n += item[1]}

puts "Indexed sources: #{indexed_sources}, Unloadable sources: #{error_sources}"

Pathname.new(REINDEX_PIDFILE).delete
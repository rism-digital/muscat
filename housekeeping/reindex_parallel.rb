parallel_jobs = 8
max_batch_size = 5000

Pathname.new(REINDEX_PIDFILE).write(Process.pid)

def human_duration(seconds)
    total_seconds = seconds.round
    hours, remainder = total_seconds.divmod(3600)
    minutes, seconds = remainder.divmod(60)
    format("%02d:%02d:%02d", hours, minutes, seconds)
end

def duration_trend(durations)
    return ["steady", 0.0, durations.first.to_f, durations.first.to_f] if durations.length < 2

    midpoint = (durations.length / 2.0).ceil
    first_average = durations.first(midpoint).sum.fdiv(midpoint)
    second_half = durations.drop(midpoint)
    second_average = second_half.sum.fdiv(second_half.length)
    change = first_average.zero? ? 0.0 : ((second_average - first_average) / first_average) * 100
    trend = change > 5 ? "slower" : change < -5 ? "accelerated" : "steady"
    [trend, change, first_average, second_average]
end

@parallel_jobs = ENV.fetch('MUSCAT_PARALLEL_JOBS', parallel_jobs).to_i
@parallel_jobs = parallel_jobs unless @parallel_jobs > 0

@max_batch_size = ENV.fetch('MUSCAT_BATCH_SIZE', max_batch_size).to_i
@max_batch_size = max_batch_size unless @max_batch_size > 0

# Split the row count evenly and use OFFSET once to find each worker's first source ID.
# Each worker then seeks from its last ID, keeping full final batches and a small intentional overlap.
@source_count = Source.all.count
@sources_per_chunk = @source_count / @parallel_jobs
@remainder = @source_count - (@sources_per_chunk * @parallel_jobs)
batch_count = [(@sources_per_chunk.to_f / @max_batch_size).ceil, 1].max
@batch_size = [(@sources_per_chunk.to_f / batch_count).ceil, 1].max

begin_time = Time.now
puts "Reindexing #{@source_count} sources in #{@parallel_jobs} processes with a remainder of #{@remainder} (#{@sources_per_chunk} per chunk), commit size #{@batch_size} (maximum #{@max_batch_size})"

chunk_start_ids = (0...@parallel_jobs).map do |jobid|
    Source.order(:id).offset(@sources_per_chunk * jobid).pick(:id)
end

results = Parallel.map(0..@parallel_jobs - 1, in_processes: @parallel_jobs) do |jobid|
    job_begin_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    offset = @sources_per_chunk * jobid
    start_id = chunk_start_ids[jobid]
    last_id = nil

    limit = @sources_per_chunk
    # On the last job add the remainder
    limit += @remainder if jobid == @parallel_jobs - 1
    rounded_limit = (limit.to_f / @batch_size).ceil * @batch_size
    range_end = offset + rounded_limit - 1


    current_limit = 0
    e_count = 0
    chunk_times = []
    while current_limit < limit
        chunk_begin_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        scope = Source.order(:id)
        scope = if last_id
            scope.where("id > ?", last_id)
        else
            scope.where("id >= ?", start_id)
        end
        batch = scope.limit(@batch_size).to_a
        break if batch.empty?

        begin
            batch.each(&:prepare_marc_for_index!)
            Sunspot.index(batch)
        rescue => e
            puts "OOPS: #{e.exception}"
            e_count += 1
        end
        last_id = batch.last.id
        current_limit += @batch_size
        chunk_run_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - chunk_begin_time
        chunk_times << chunk_run_time
        puts "JOB #{jobid} RANGE #{offset}-#{range_end} INDEXED #{current_limit}/#{rounded_limit} CHUNK TIME #{human_duration(chunk_run_time)}"
    end
    job_run_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - job_begin_time
    average_chunk_time = chunk_times.empty? ? 0.0 : chunk_times.sum / chunk_times.length
    trend, change, first_average, second_average = duration_trend(chunk_times)
    puts "-JOB #{jobid} FINISHED #adios indexed:#{current_limit} oopsies:#{e_count} run time:#{human_duration(job_run_time)} avg chunk:#{human_duration(average_chunk_time)} trend:#{trend} (#{format('%+.1f', change)}%, first:#{human_duration(first_average)} second:#{human_duration(second_average)})"
    [current_limit, e_count]


=begin
    count = 0
    e_count = 0
    Source.order(:id).limit(limit).offset(offset).select(:id).each do |sid|
        s = Source.find(sid.id)
            s.marc.load_source false

        begin
            Sunspot.index s
            count += 1
        rescue => e
            puts "Could not load #{sid.id}: #{e.exception}"
            e_count += 1
        end
        puts "#{jobid} - #{count}" if count % 1000 == 0
    end
    
    [count, e_count]
=end
end

Sunspot.commit

end_time = Time.now
puts "Reindex started at #{begin_time.to_s}, ended at: #{end_time.to_s}"
total_run_time = end_time - begin_time
puts "(#{total_run_time} seconds run time = #{human_duration(total_run_time)})"
puts "Results are: #{results.to_s}"

indexed_sources = results.inject(0){|n, item| n += item[0]}
error_sources = results.inject(0){|n, item| n += item[1]}

puts "Indexed sources: #{indexed_sources}, Unloadable sources: #{error_sources}"

Pathname.new(REINDEX_PIDFILE).delete

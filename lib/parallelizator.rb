require "parallel"

class Parallelizator
  Result = Struct.new(:jobid, :processed, :errors, :duration_s, keyword_init: true)

  def initialize(model_or_relation,
                 fn,
                 jobs: ENV.fetch("MUSCAT_PARALLEL_JOBS", 8).to_i,
                 batch_size: 5_000,
                 order: :id,
                 mode: :record,
                 backend: :processes,      # :processes or :threads
                 on_error: nil,
                 where_sql: nil)
    @relation   = model_or_relation.respond_to?(:all) ? model_or_relation.all : model_or_relation
    @fn         = fn
    @jobs       = [jobs.to_i, 1].max
    @batch_size = [batch_size.to_i, 1].max
    @order      = order
    @mode       = mode
    @backend    = backend
    @on_error   = on_error
    @where_sql  = where_sql
  end

  def run
    total = @relation.count
    return [] if total == 0

    jobs = [@jobs, total].min
    per_chunk = total / jobs
    remainder = total - (per_chunk * jobs)

    # Setup our progressbar
    # we need to calculate the full set
    scope0 = @relation
    scope0 = scope0.where(@where_sql) if @where_sql.present?

    # Cool atomic counter!
    bar_status = Concurrent::AtomicFixnum.new(0)

    bar = ProgressBar.create(
      total: scope0.count,
      format: "%a %B %p%% %t (processed: %c/%C)"
    )

    stop = Concurrent::AtomicBoolean.new(false)
    renderer = Thread.new do
      last = 0
      until stop.true?
        sleep 0.2
        cur = bar_status.value
        if cur != last
          bar.progress = cur
          last = cur
        end
      end
      bar.progress = bar_status.value
      bar.finish
    end

    parallel_opts =
      if @backend == :threads
        { in_threads: jobs }
      else
        { in_processes: jobs }
      end

    Parallel.map(0...jobs, **parallel_opts) do |jobid|
      # Important for ActiveRecord + threads:
      # ensure each thread checks out its own DB connection.
      ActiveRecord::Base.connection_pool.with_connection do
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        offset = per_chunk * jobid
        limit  = per_chunk
        limit += remainder if jobid == jobs - 1

        processed = 0
        errors = 0
        cursor = 0

        while cursor < limit
          scope = @relation
          scope = scope.where(@where_sql) if @where_sql.present?

          batch = scope.order(@order).limit(@batch_size).offset(offset + cursor).to_a
          break if batch.empty?

          begin
            if @mode == :batch
              @fn.call(batch)
              processed += batch.size
              bar_status.increment(batch.size)
            else
              batch.each do |record|
                @fn.call(record)
                processed += 1
                bar_status.increment(1)
              end
            end
          rescue => e
            errors += 1
            @on_error&.call(jobid, e, { offset: offset, cursor: cursor, limit: limit, batch_size: @batch_size })
          end

          cursor += @batch_size
        end

        ended = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        Result.new(jobid: jobid, processed: processed, errors: errors, duration_s: (ended - started))
      end
    end
    
    stop.make_true
    renderer.join
  end

  def self.summarize(results)
    {
      jobs: results.size,
      processed: results.sum(&:processed),
      errors: results.sum(&:errors),
      duration_s: results.sum(&:duration_s)
    }
  end
end

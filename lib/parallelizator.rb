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
                 on_error: nil)
    @relation   = model_or_relation.respond_to?(:all) ? model_or_relation.all : model_or_relation
    @fn         = fn
    @jobs       = [jobs.to_i, 1].max
    @batch_size = [batch_size.to_i, 1].max
    @order      = order
    @mode       = mode
    @backend    = backend
    @on_error   = on_error
  end

  def run
    total = @relation.count
    return [] if total == 0

    jobs = [@jobs, total].min
    per_chunk = total / jobs
    remainder = total - (per_chunk * jobs)

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
          batch = @relation.order(@order).limit(@batch_size).offset(offset + cursor).to_a
          break if batch.empty?

          begin
            if @mode == :batch
              @fn.call(batch)
              processed += batch.size
            else
              batch.each do |record|
                @fn.call(record)
                processed += 1
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

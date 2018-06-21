class LogModelErrorsJob < ApplicationJob
  queue_as :default
  
  def initialize
    super
    @parallel_jobs = 10
    @all_src = Source.all.count
    @limit = @all_src / @parallel_jobs
  end
  
  def perform(*args)
    errors = []
    count = 0
    results = Parallel.map(0..@parallel_jobs, in_processes: @parallel_jobs, progress: "Doing stuff") do |jobid|
      offset = @limit * jobid

      Source.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
        s = Source.find(sid.id)
        begin
          s.marc.load_source true
        rescue
          errors << sid.id
        end
        
      end
      errors
    end
    
  end
  
end

require 'stringio'
class LogModelErrorsJob < ApplicationJob
  queue_as :default
  
  def initialize
    super
    @parallel_jobs = 10
    @all_src = Source.all.count
    @limit = @all_src / @parallel_jobs
  end
  
  def perform(*args)
    # Capture all the puts from the inner classes
    new_stdout = StringIO.new
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = new_stdout
    $stderr = new_stdout
    String.disable_colorization true
    
    count = 0
    
    results = Parallel.map(0..@parallel_jobs, in_processes: @parallel_jobs) do |jobid|
      errors = {}
      offset = @limit * jobid

      Source.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
        s = Source.find(sid.id)
        begin
          s.marc.load_source true
        rescue
          errors[sid.id] = new_stdout.string
          new_stdout.rewind
        end
        
      end
      errors
    end
    
    $stdout = old_stdout
    $stderr = old_stderr
    
    h = results.reduce(&:merge)
    HealthReport.notify("Source", "Report", h).deliver_now
    
  end
  
end

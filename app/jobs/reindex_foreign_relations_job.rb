class ReindexForeignRelationsJob < ProgressJob::Base
  
  def initialize(parent_id, relations)
    @parent_id = parent_id
    @relations = relations
  end
  
  def enqueue(job)
    if @parent_id
      job.parent_id = @parent_id
      job.parent_type = "Source"
      job.save!
    end
  end

  def perform
    
    update_stage("Starting up")
    update_progress_max(@relations.count)

    @relations.each do |element|
      # If the job manager goes down, jobs may pile up
      # It can happen that a referenced element gets deleted
      # Just skip it if it does not exists, this way the
      # job itelf does not crash
      next if !element[:class].exists?(element[:id])
      
      link = element[:class].find(element[:id])
      begin
        link.reindex
      rescue Errno::ECONNREFUSED
        sleep rand(5)
        link.reindex
      end
      update_stage_progress("Reindexing #{link.class} relation", step: 1)
    end
  end
  
  
  def destroy_failed_jobs?
    false
  end
  
  def max_attempts
    1
  end
  
  def queue_name
    'authority'
  end
end
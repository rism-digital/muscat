class ReindexAuthorityJob < ProgressJob::Base
  
  def initialize(parent_obj)
    @parent_obj = parent_obj
  end
  
  def enqueue(job)
    if @parent_obj
      job.parent_id = @parent_obj.id
      job.parent_type = @parent_obj.class
      job.save!
    end
  end

  def perform
    return if !@parent_obj
    
    update_progress_max(0)
        
    update_stage("Init Reindex process...")
    update_progress_max(@parent_obj.sources.count)
    
    update_stage("Look up Sources")
    batch = 1
    @parent_obj.sources.find_in_batches(batch_size: 50) do |group|
      Sunspot.index group
      Sunspot.commit
      update_stage_progress("Updating records #{batch * 50}/#{@parent_obj.sources.count}", step: 50)
      batch += 1
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
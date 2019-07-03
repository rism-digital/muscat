class ReindexItemsJob < ProgressJob::Base
  
  def initialize(parent_obj, relation = "referring_sources")
    @parent_obj = parent_obj
    @relation = relation
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
    
    update_progress_max(-1)
    items = @parent_obj.send(@relation)
    
    update_stage("Look up Sources")
    update_progress_max(@parent_obj.referring_sources.count)
    batch = 1
    items.find_in_batches(batch_size: 10) do |group|
      Sunspot.index group
      Sunspot.commit
      update_stage_progress("Updating records #{batch * 10}/#{@parent_obj.referring_sources.count}", step: 10)
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

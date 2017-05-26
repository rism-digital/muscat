class SaveItemsJob < ProgressJob::Base
  
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
    return if !@relation
    
    items = @parent_obj.send(@relation)
    
    update_progress_max(-1)
    update_stage("Look up #{@relation}")
    update_progress_max(items.count)
    
    count = 1
    items.each do |i|
      i.paper_trail_event = "auth save"
      # By the time the job executes, things can get stale
      next if !i.class.exists?(i.id)
      # Force a reload of the object
      reloaded_element = i.class.find(i.id)
      # let the job crash in case
      reloaded_element.save
      update_stage_progress("Saving record #{count}/#{items.count}", step: 1)
      count += 1
    end
    
    update_stage("Reindexing parent")
    # reindex the parent obj as needed
    if @parent_obj.respond_to? :reindex
      @parent_obj.reindex
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
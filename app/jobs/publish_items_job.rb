 class PublishItemsJob < ProgressJob::Base
  
  def initialize(parent_obj_id, parent_obj_class, relation = :referring_sources, action = :publish)
    @parent_obj_id = parent_obj_id
    @parent_obj_class = parent_obj_class
    @relation = relation
    @action = action
  end
  
  def enqueue(job)
    return if !@parent_obj_id || !@parent_obj_class

    # We want a class here
    return if !@parent_obj_class.is_a? Class

    job.parent_id = @parent_obj_id
    job.parent_type = @parent_obj_class
    job.save!

  end

  def perform
    return if !@parent_obj_id
    
    #update_progress_max(0)
    
    begin
      parent_obj = @parent_obj_class.send("find", @parent_obj_id)
    rescue ActiveRecord::RecordNotFound
      return # Just exit
    end

    update_stage("Publish items")
    items = parent_obj.send(@relation)

    update_progress_max(items.count)
    
    new_wf_stage = @action == :unpublish ? :inprogress : :published
    
    action = new_wf_stage == :published ? "Publish" : "Unpublish"

    count = 0
    items.each do |fi|
      fi = fi.item if fi.is_a?(FolderItem) 

      fi.wf_stage = new_wf_stage
      
      if  PaperTrail.request.enabled_for_model?(fi.class) 
        fi.paper_trail_event = "#{action} folder #{@parent_obj_id}"
      end

      fi.save
      
      update_stage_progress("Updating records #{count}/#{items.count}", step: 1)
      count += 1
    end
    
  end
  
  
  def destroy_failed_jobs?
    false
  end
  
  def max_attempts
    1
  end
  
  def queue_name
    'resave'
  end
end

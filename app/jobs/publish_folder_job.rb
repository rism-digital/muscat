class PublishFolderJob < ProgressJob::Base
  
  def initialize(parent_id, options = {})
    @parent_id = parent_id
    @options = options
  end
  
  def enqueue(job)
    if @parent_id
      job.parent_id = @parent_id
      job.parent_type = "folder"
      job.save!
    end
  end

  def perform
    return if !@parent_id
    
    update_progress_max(0)
        
    update_stage("Publish items")
    f2 = Folder.find(@parent_id)
    
    update_progress_max(f2.folder_items.count)
    
    new_wf_stage = @options.include?(:unpublish) && @options[:unpublish] == true ? :inprogress : :published
    
    count = 0
    f2.folder_items.each do |fi|
      fi.item.wf_stage = new_wf_stage
      
      if  PaperTrail.request.enabled_for_model?(fi.item.class) 
        fi.item.paper_trail.without_versioning :save
      else
        fi.item.save
      end
      update_stage_progress("Updating records #{count}/#{f2.folder_items.count}", step: 1)
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
    'folders'
  end
end

class ReindexFolderJob < ProgressJob::Base
  
  def initialize(parent_id)
    @parent_id = parent_id
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
        
    update_stage("Init Reindex process...")
    f2 = Folder.find(@parent_id)    
    update_progress_max(f2.folder_items.count)
    
    update_stage("Look up Sources")
    batch = 1
    Source.in_folder(@parent_id).find_in_batches(batch_size: 50) do |group|
      Sunspot.index group
      Sunspot.commit
      update_stage_progress("Updating records #{batch * 50}/#{f2.folder_items.count}", step: 50)
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
    'folders'
  end
end
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
        
    update_stage("Reindex items")
    f2 = Folder.find(@parent_id)
    
    update_progress_max(f2.folder_items.count)
    
    batch = 1
    f2.folder_items.find_in_batches(batch_size: 100) do |group|
      Sunspot.index group
      Sunspot.commit
      update_stage_progress("Updating records #{batch * 100}/#{f2.folder_items.count}", step: 100)
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
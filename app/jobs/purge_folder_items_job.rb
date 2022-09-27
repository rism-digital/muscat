class PurgeFolderItemsJob < ProgressJob::Base
  
  def initialize(parent_id = nil)
    @parent_id = parent_id
  end
  
  def enqueue(job)
    # if @parent_id is defined we are running from the interface
    if @parent_id
      job.parent_id = @parent_id
      job.parent_type = "folder"
      job.save!
    end
  end

  def perform(*args)
    update_progress_max(100) if @parent_id
    update_stage_progress("Cleaning up FolderItems", step: 50) if @parent_id

    # set a batch_size big enough so it does not take forever
    FolderItem.solr_clean_index_orphans(batch_size: 50000)
    update_stage_progress("Done", step: 100) if @parent_id
    Sunspot.commit
  end

  def destroy_failed_jobs?
    false
  end
  
  def max_attempts
    1
  end
  
  def queue_name
    'reindex'
  end
end

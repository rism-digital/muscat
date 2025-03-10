class AddToFolderJob < ProgressJob::Base
  
  def initialize(parent_id, params, model)
    @parent_id = parent_id
    @params = params
    @model = model
  end
  
  def enqueue(job)
    if @parent_id
      job.parent_id = @parent_id
      job.parent_type = "Folder"
      job.save!
    end
  end

  def perform
    return if !@parent_id
    
		update_stage("Loading items")
		
    f = Folder.find(@parent_id)
		update_progress_max(0)
    
    @params[:per_page] = 1000
    results, hits = @model.search_as_ransack(@params)
    
    all_items = []
    results.each { |s| all_items << s }
    # insert the next ones
    for page in 2..results.total_pages
      @params[:page] = page
      r, h = @model.search_as_ransack(@params)
      r.each { |s| all_items << s }
    end
    
		update_stage("Adding Items")
		# Round to the nearest top multiple of 50
		update_progress_max((all_items.count / 50.0).round * 50)
		
		# this yields every 50 items
    added_items = f.add_items(all_items) {|nr| update_stage_progress("Adding item #{nr}", step: 50)}
    
		update_stage("Added #{added_items}/#{all_items.count}, reindex")
		# Hack
    f2 = Folder.find(f.id)
    Sunspot.index f2.folder_items
    Sunspot.commit
    
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
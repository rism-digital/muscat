class MakePublicationsCataloguesFromFolder < ProgressJob::Base
  
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
          
      update_stage("Add 'work_catalog' flag")
      f2 = Folder.find(@parent_id)
      return if f2.folder_type != "Publication"

      update_progress_max(f2.folder_items.count)
        
      count = 0
      f2.folder_items.each do |fi|
        fi.item.work_catalogue = true
        
        if  PaperTrail.request.enabled_for_model?(fi.item.class) 
          fi.item.paper_trail_event = "Add work_catalog flag from folder #{@parent_id}"
        end
        
        fi.item.save
        
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
      'resave'
    end
  end
  
class MakePublicationsCataloguesFromFolder < ProgressJob::Base
  
    def initialize(parent_id, status_flag)
      @parent_id = parent_id
      @status_flag = status_flag
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
          
      update_stage("Set work_catalog flag to #{@status_flag}")
      f2 = Folder.find(@parent_id)
      return if f2.folder_type != "Publication"

      update_progress_max(f2.folder_items.count)
        
      count = 0
      f2.folder_items.each do |fi|
        fi.item.work_catalogue = @status_flag.to_sym
        
        if  PaperTrail.request.enabled_for_model?(fi.item.class) 
          fi.item.paper_trail_event = "Set work_catalog flag from folder #{@parent_id}"
        end
        
        fi.item.save
        fi.item.reindex
        
        update_stage_progress("Updating records #{count}/#{f2.folder_items.count}", step: 1)
        count += 1
      end
      
      Sunspot.commit
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
  
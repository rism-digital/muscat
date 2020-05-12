class ExportRecordsJob < ProgressJob::Base
  
    def initialize(parent_obj_id, parent_obj_class)
      @parent_obj_id = parent_obj_id
      @parent_obj_class = parent_obj_class
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
        
        update_stage("Starting export")

        f = Folder.find(@parent_obj_id)

        update_progress_max(f.folder_items.count)

        File.open("#{Rails.root}/tmp/test.xml", "w") do |file| 
            f.folder_items.limit(30000).each do |f|
                file.write(f.item.marc.to_xml_record(nil, nil, true))
                update_stage_progress("Exporting #{f.item.id}")
            end
        end
      
    end
    
    def destroy_failed_jobs?
      false
    end
    
    def max_attempts
      1
    end
    
    def queue_name
      'export'
    end
end
  
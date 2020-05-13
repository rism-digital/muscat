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

 
=begin
        File.open("#{Rails.root}/tmp/test.xml", "w") do |file| 
            f.folder_items.limit(30000).each do |f|
                file.write(f.item.marc.to_xml_record(nil, nil, true))
                update_stage_progress("Exporting #{f.item.id}")
            end
        end
=end
        # Force a reconnect


        limit = f.folder_items.count / 10
        max = f.folder_items.count
        update_progress_max(max)
        count = 0
        Parallel.map(0..10, in_processes: 10) do |jobid|
            ActiveRecord::Base.connection.reconnect!
            offset = limit * jobid
            File.open("#{Rails.root}/tmp/test#{jobid}.xml", "w") do |file|
                f.folder_items.order(:id).limit(limit).offset(offset).each do |fi|
                    file.write(fi.item.marc.to_xml_record(nil, nil, true))
                    count += 1
                    update_stage_progress("Updated #{count * 10}/#{max}", step: 200) if count % 20 == 0 && jobid == 0
                end
            end
            ActiveRecord::Base.connection.reconnect!
        end
        ActiveRecord::Base.connection.reconnect!
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
  
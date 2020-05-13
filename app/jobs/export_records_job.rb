class ExportRecordsJob < ProgressJob::Base
    
    MAX_PROCESSES = 10

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

        limit = f.folder_items.count / MAX_PROCESSES
        max = f.folder_items.count
        update_progress_max(max)

        # Let's make enough tempfiles
        tempfiles = []
        (1..MAX_PROCESSES).each {tempfiles << Tempfile.new('export')}

        Parallel.map(0..MAX_PROCESSES - 1, in_processes: MAX_PROCESSES) do |jobid|
            ActiveRecord::Base.connection.reconnect!
            offset = limit * jobid
            count = 0
            #File.open("#{Rails.root}/tmp/test#{jobid}.xml", "w") do |file|
            f.folder_items.order(:id).limit(limit).offset(offset).each do |fi|
                tempfiles[jobid].write(fi.item.marc.to_xml_record(nil, nil, true))
                # We approximante the progress by having only one process write to it
                if jobid == 0
                    count += 1
                    update_stage_progress("Exported #{count * MAX_PROCESSES}/#{max}", step: 200) if count % 20 == 0 && jobid == 0
                end
            end
            #end
            tempfiles[jobid].rewind
            ActiveRecord::Base.connection.reconnect!
        end
        ActiveRecord::Base.connection.reconnect!

        update_stage("Finalizing export")

        # Now concatenate the files together
        time = Time.now.strftime('%Y-%m-%d_%H%M%S')
        filename = "export_#{time}"
        File.open("#{Rails.root}/public/#{filename}.xml", "w") do |file|
            tempfiles.each {|tf| file.write(tf.read)}
        end

        # Compress it so the user soes not faint
        Zip::File.open("#{Rails.root}/public/#{filename}.zip", Zip::File::CREATE) do |zipfile|
            zipfile.add(filename + ".xml", "#{Rails.root}/public/#{filename}.xml")
        end
          
        File.unlink("#{Rails.root}/public/#{filename}.xml")

        # Clean up the tempfiles
        tempfiles.each {|tf| tf.close; tf.unlink}

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
  
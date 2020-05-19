class ExportRecordsJob < ProgressJob::Base
    
    MAX_PROCESSES = 10

    def initialize(type = :folder, options = {})
      @type = type
      @job_options = options
    end
    
    def enqueue(job)
      return if @type != :folder && @type != :catalog
  
      if @type == :folder 
        if @job_options.include?(:id)
          job.parent_id = @job_options[:id]
        else
          throw "Cannot export folder without id"
        end
      end

      job.parent_type = @type.to_s
      job.save!
  
    end
  
    def perform
      update_stage("Starting export")

      if @type == :folder
        @getter = FolderGetter.new(@job_options[:id])
      else
        @getter = CatalogGetter.new(@job_options[:search_params])
      end

      if @getter.get_item_count > 500
        filename = export_parallel
      else
        filename = export
      end
      
      # Compress it so the user soes not faint
      Zip::File.open("#{Rails.root}/public/#{filename}.zip", Zip::File::CREATE) do |zipfile|
          zipfile.add(filename + ".xml", "#{Rails.root}/public/#{filename}.xml")
      end
        
      File.unlink("#{Rails.root}/public/#{filename}.xml")
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

private

  def export_parallel
    limit = @getter.get_item_count / MAX_PROCESSES
    max = @getter.get_item_count
    update_progress_max(max)

    # Let's make enough tempfiles
    tempfiles = []
    (1..MAX_PROCESSES).each {tempfiles << Tempfile.new('export')}

    Parallel.map(0..MAX_PROCESSES - 1, in_processes: MAX_PROCESSES) do |jobid|
        ActiveRecord::Base.connection.reconnect!
        count = 0
        # Account for rounding errors
        #if jobid == 9
        #  limit += max - limit * MAX_PROCESSES
        #end
        #f.folder_items.order(:id).limit(limit).offset(offset).each do |fi|
        @getter.get_items_in_range(jobid, limit).each do |source_id|
          source = Source.find(source_id)
          tempfiles[jobid].write(source.marc.to_xml_record(nil, nil, true))
          # We approximante the progress by having only one process write to it
          if jobid == 0
              count += 1
              update_stage_progress("Exported #{count * MAX_PROCESSES}/#{max}", step: 200) if count % 20 == 0 && jobid == 0
          end
          source = nil
        end
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

    # Clean up the tempfiles
    tempfiles.each {|tf| tf.close; tf.unlink}

    return filename
  end

  def export
    count = 0
    time = Time.now.strftime('%Y-%m-%d_%H%M%S')
    filename = "export_#{time}"

    update_progress_max(@getter.get_item_count)

    File.open("#{Rails.root}/public/#{filename}.xml", "w") do |file|
      @getter.get_items.each do |source_id|
        source = Source.find(source_id)
        file.write(source.marc.to_xml_record(nil, nil, true))
        count += 1
        update_stage_progress("Exported #{count}/#{@getter.get_item_count} [s]", step: 20) if count % 20 == 0
      end
    end

    return filename
  end

  class FolderGetter
    def initialize(folder_id)
      @folder = Folder.find(folder_id)
    end

    def get_item_count
      @folder.folder_items.count
    end

    def get_items_in_range(slice, limit)
      offset = limit * slice
      return @folder.folder_items.order(:id).limit(limit).offset(offset).collect {|fi| fi.item.id}
    end

    def get_items
      return @folder.folder_items.collect {|fi| fi.item.id}
    end
  end

  class CatalogGetter
    def initialize(search_params)
      @catalog_search = CatalogSearch.new(EXPORT_USER, EXPORT_PASS)
      @results = @catalog_search.search(search_params)
    end

    def get_item_count
      @results.count
    end

    def get_items_in_range(slice, limit)
      @results.in_groups(MAX_PROCESSES, false)[slice]
    end

    def get_items
      return @results
    end
  end

end
  
require 'zip'

class ExportRecordsJob < ProgressJob::Base
    
  MAX_PROCESSES = 10

  EXPORT_PATH = Rails.public_path.join('export')

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
      # Note: a deleted folder will crash the job
      # We don't trap it so we have a log in the jobs
      @getter = FolderGetter.new(@job_options[:id])
    else
      update_stage("Running query")
      @getter = CatalogGetter.new(@job_options[:search_params])
    end

    if @getter.get_item_count > 500
      filename = export_parallel
    else
      filename = export
    end
    
    # Compress it so the user soes not faint
    Zip::File.open(EXPORT_PATH.join(filename + '.zip'), Zip::File::CREATE) do |zipfile|
        zipfile.add(filename + '.xml', EXPORT_PATH.join(filename + '.xml'))
    end
      
    File.unlink(EXPORT_PATH.join(filename + '.xml'))

    # Send the user a notification
    ExportReadyNotification.notify(@job_options[:email], filename + ".zip").deliver_now

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
    max = @getter.get_item_count
    update_progress_max(max)

    # Let's make enough tempfiles
    tempfiles = []
    (1..MAX_PROCESSES).each {tempfiles << Tempfile.new('export')}

    Parallel.map(0..MAX_PROCESSES - 1, in_processes: MAX_PROCESSES) do |jobid|
        ActiveRecord::Base.connection.reconnect!
        count = 0

        @getter.get_items_in_range(jobid, MAX_PROCESSES).each do |source_id|
          begin
            source = Source.find(source_id)
          rescue ActiveRecord::RecordNotFound
            next
          end

          tempfiles[jobid].write(source.marc.to_xml_record(nil, nil, true))

          # We approximante the progress by having only one process write to it
          if jobid == 0
              count += 1
              update_stage_progress("Exported #{count * MAX_PROCESSES}/#{max}", step: 200) if count % 20 == 0 && jobid == 0
          end
          # Force a cleanup
          source = nil
        end
        tempfiles[jobid].rewind
        ActiveRecord::Base.connection.reconnect!
    end
    ActiveRecord::Base.connection.reconnect!

    update_stage("Finalizing export")

    # Now concatenate the files together
    filename = create_filename

    File.open(EXPORT_PATH.join(filename + '.xml'), "w") do |file|
      file.write(xml_preamble)
      tempfiles.each {|tf| file.write(tf.read)}
      file.write(xml_conclusion)
    end

    # Clean up the tempfiles
    tempfiles.each {|tf| tf.close; tf.unlink}

    return filename
  end

  def export
    count = 0
    filename = create_filename

    update_progress_max(@getter.get_item_count)

    File.open(EXPORT_PATH.join(filename + '.xml'), "w") do |file|
      file.write(xml_preamble)

      @getter.get_items.each do |source_id|
        source = Source.find(source_id)
        file.write(source.marc.to_xml_record(nil, nil, true))
        count += 1
        update_stage_progress("Exported #{count}/#{@getter.get_item_count} [s]", step: 20) if count % 20 == 0
      end

      file.write(xml_conclusion)
    end

    return filename
  end

  def create_filename
    time = Time.now.strftime('%Y-%m-%d-%H%M')
    filename = "export-#{time}-" + SecureRandom.hex(4)
  end

  def xml_preamble
    out = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    out += "<!-- Exported from RISM Muscat (#{@type}) Date: #{Time.now.utc} -->\n"
    out += "<marc:collection xmlns:marc=\"http://www.loc.gov/MARC21/slim\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd\">\n"
    return out
  end

  def xml_conclusion
    "</marc:collection>" 
  end

  class FolderGetter
    def initialize(folder_id)
      @folder = Folder.find(folder_id)
    end

    def get_item_count
      @folder.folder_items.count
    end

    def get_items_in_range(slice, max_slices)
      #return @folder.folder_items.order(:id).limit(limit).offset(offset).collect {|fi| fi.item.id}
      # Every time you do something by hand, Rails has a better way
      return @folder.folder_items.in_groups(max_slices, false)[slice].collect {|fi| fi.item.id}
    end

    def get_items
      return @folder.folder_items.collect {|fi| fi.item.id}
    end
  end

  class CatalogGetter
    def initialize(search_params)
      @catalog_search = CatalogSearch.new(Rails.application.credentials.export[:user], Rails.application.credentials.export[:password])
      @results = @catalog_search.search(search_params)
    end

    def get_item_count
      @results.count
    end

    def get_items_in_range(slice, max_slices)
      @results.in_groups(max_slices, false)[slice]
    end

    def get_items
      return @results
    end
  end

end
  
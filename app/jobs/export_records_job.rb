require 'zip'

class ExportRecordsJob < ProgressJob::Base
    
  MAX_PROCESSES = 10

  EXPORT_PATH = Rails.public_path.join('export')

  def initialize(type = :folder, options = {})
    @type = type
    @job_options = options

    @format = :xml
    @extension = ".xml"
    if @job_options.include?(:format)
      if @job_options[:format] == :csv
        @format = :csv
        @extension = ".csv"
      end
    end
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
        zipfile.add(filename + @extension, EXPORT_PATH.join(filename + @extension))
    end
      
    File.unlink(EXPORT_PATH.join(filename + @extension))

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
        if @format == :xml
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
        else
          headers = csv_headers
          CSV.open(tempfiles[jobid].path, "wb", headers: headers, write_headers: jobid == 0 ? true : false) do |csv|
            @getter.get_items_in_range(jobid, MAX_PROCESSES).each do |source_id|
              begin
                source = Source.find(source_id)
              rescue ActiveRecord::RecordNotFound
                next
              end

              csv << marc2csv(source)
              if jobid == 0
                count += 1
                update_stage_progress("Exported #{count * MAX_PROCESSES}/#{max}", step: 200) if count % 20 == 0 && jobid == 0
              end
              source = nil
            end
          end
        end

        tempfiles[jobid].rewind
        ActiveRecord::Base.connection.reconnect!
    end
    ActiveRecord::Base.connection.reconnect!

    update_stage("Finalizing export")

    # Now concatenate the files together
    filename = create_filename

    File.open(EXPORT_PATH.join(filename + @extension), "w") do |file|
      file.write(xml_preamble) if @format == :xml
      tempfiles.each {|tf| file.write(tf.read)}
      file.write(xml_conclusion) if @format == :xml
    end

    # Clean up the tempfiles
    tempfiles.each {|tf| tf.close; tf.unlink}

    return filename
  end

  def export
    count = 0
    filename = create_filename

    update_progress_max(@getter.get_item_count)

    if @format == :xml
      File.open(EXPORT_PATH.join(filename + @extension), "w") do |file|
        file.write(xml_preamble)

        @getter.get_items.each do |source_id|
          source = Source.find(source_id)
          file.write(source.marc.to_xml_record(nil, nil, true))
          count += 1
          update_stage_progress("Exported #{count}/#{@getter.get_item_count} [s]", step: 20) if count % 20 == 0
        end

        file.write(xml_conclusion)
      end
    else
      headers = csv_headers
      CSV.open(EXPORT_PATH.join(filename + @extension), "wb", headers: headers, write_headers: true) do |csv|
        @getter.get_items.each do |source_id|
          source = Source.find(source_id)
            csv << marc2csv(source)
            count += 1
            update_stage_progress("Exported #{count}/#{@getter.get_item_count} [s]", step: 20) if count % 20 == 0
        end
      end
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

  def csv_headers
    [:record_id, :signature, :copies, :in, :composer, :title, :standard_title, :literature, :keywords, :source_type, :date_to, :date_from, :material, :plate_no ]
  end

  def marc2csv(source)
    csv_line = {}
    
    csv_line[:record_id] = source.id
    if source.holdings.count > 0
        signature = []
        source.holdings.each do |h|
            h.marc.each_by_tag("852") do |t|
                ta = t.fetch_first_by_tag("a").content rescue ta = ""
                tc = t.fetch_first_by_tag("c").content rescue tc = ""

                signature << ta + " " + tc
            end
        end
        csv_line[:signature] = signature.join("\n")
        csv_line[:copies] = ""
    else
        csv_line[:signature] = source.lib_siglum + " " + source.shelf_mark
        csv_line[:copies] = ""
    end

    if source.parent_source
        csv_line[:in] = source.parent_source.id
    else
        csv_line[:in] = ""
    end

    csv_line[:composer] = source.composer
    csv_line[:title] = source.title
    csv_line[:standard_title] = source.std_title

    literature = []
    source.marc.each_by_tag("690") do |t|
        ta = t.fetch_first_by_tag("a").content rescue ta = ""
        tn = t.fetch_first_by_tag("n").content rescue tn = ""

        literature << ta + " " + tn
    end
    csv_line[:literature] = literature.join("\n")

    keywords = []
    source.marc.each_by_tag("650") do |t|
      ta = t.fetch_first_by_tag("a").content rescue ta = ""

      keywords << ta
    end
    csv_line[:keywords] = keywords.join("\n")

    csv_line[:source_type] = ""
    t = source.marc.first_occurance("593")
    if t
      ta = t.fetch_first_by_tag("a").content rescue ta = ""
      csv_line[:source_type] = ta
    end

    csv_line[:date_to] = source.date_to
    csv_line[:date_from] = source.date_from

    material = []
    source.marc.each_by_tag("300") do |t|
      ta = t.fetch_first_by_tag("a").content rescue ta = ""

      material << ta
    end
    csv_line[:material] = material.join("\n")

    plate = []
    source.marc.each_by_tag("0128") do |t|
      ta = t.fetch_first_by_tag("a").content rescue ta = ""

      plate << ta
    end
    csv_line[:plate] = plate.join("\n")

    return csv_line
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
  
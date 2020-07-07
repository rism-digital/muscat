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

    @controller = @job_options.include?(:controller) && @job_options[:controller]

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
      @getter = CatalogGetter.new(@job_options[:search_params], @controller)
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
          header_mapper = lambda { |header| csv_headers[header] }
          CSV.open(tempfiles[jobid].path, "wb", headers: headers.keys, write_headers: jobid == 0 ? true : false, header_converters: header_mapper) do |csv|
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
      header_mapper = lambda { |header| csv_headers[header] }
      CSV.open(EXPORT_PATH.join(filename + @extension), "wb", headers: headers.keys, write_headers: true, header_converters: header_mapper) do |csv|
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

  # Few things are as asinine as the headers in CSV
  # If you provide an array of values, they can match
  # thet keys in your hash of values to export.
  # But if you want a human readable label, good luck!
  # You can transform the headers with header_transform,
  # but then the match is done in the transformed output!
  # So actually to get this to work we need to map the
  # gumar readable values directly in the output hash.
  def csv_headers
    { record_id: "RISM ID",
      signature: "LIBRARY INFO (852)",
      in: "PART OF(773)",
      composer: "COMPOSER (100)",
      title: "TITLE (240)",
      standard_title: "STANDARD TITLE (240)",
      literature: "WORK CATALOG (690)",
      keywords: "SUBJECT HEADING (650)",
      source_type: "SOURCE TYPE (593)",
      date_to: "DATE TO (260)",
      date_from: "DATE FROM (260)",
      material: "MATERIAL (300)",
      plate_no: "PLATE NR (028)"
    }
  end


  def marc2csv(source)
    csv_line = {}
    
    csv_line[csv_headers[:record_id]] = source.id
    if source.holdings.count > 0
        signature = []
        source.holdings.each do |h|
            h.marc.each_by_tag("852") do |t|
                ta = t.fetch_first_by_tag("a").content rescue ta = ""
                tc = t.fetch_first_by_tag("c").content rescue tc = ""

                signature << ta + " " + tc
            end
        end
        csv_line[csv_headers[:signature]] = signature.join("\n")
    else
        csv_line[csv_headers[:signature]] = source.lib_siglum + " " + source.shelf_mark
    end

    if source.parent_source
        csv_line[csv_headers[:in]] = source.parent_source.id
    else
        csv_line[csv_headers[:in]] = ""
    end

    csv_line[csv_headers[:composer]] = source.composer
    csv_line[csv_headers[:title]] = source.title
    csv_line[csv_headers[:standard_title]] = source.std_title

    literature = []
    source.marc.each_by_tag("690") do |t|
        ta = t.fetch_first_by_tag("a").content rescue ta = ""
        tn = t.fetch_first_by_tag("n").content rescue tn = ""

        literature << ta + " " + tn
    end
    csv_line[csv_headers[:literature]] = literature.join("\n")

    keywords = []
    source.marc.each_by_tag("650") do |t|
      ta = t.fetch_first_by_tag("a").content rescue ta = ""

      keywords << ta
    end
    csv_line[csv_headers[:keywords]] = keywords.join("\n")

    csv_line[csv_headers[:source_type]] = ""
    t = source.marc.first_occurance("593")
    if t
      ta = t.fetch_first_by_tag("a").content rescue ta = ""
      csv_line[csv_headers[:source_type]] = ta
    end

    csv_line[csv_headers[:date_to]] = source.date_to
    csv_line[csv_headers[:date_from]] = source.date_from

    material = []
    source.marc.each_by_tag("300") do |t|
      ta = t.fetch_first_by_tag("a").content rescue ta = ""

      material << ta
    end
    csv_line[csv_headers[:material]] = material.join("\n")

    plate = []
    source.marc.each_by_tag("028") do |t|
      ta = t.fetch_first_by_tag("a").content rescue ta = ""

      plate << ta
    end
    csv_line[csv_headers[:plate]] = plate.join("\n")

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
    def initialize(search_params, controller)
      @catalog_search = CatalogSearch.new(Rails.application.credentials.export[:user], Rails.application.credentials.export[:password], controller)
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
  
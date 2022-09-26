# This worker il called by the user whan he want to import an image for the Digital Object system
# it searches for a ZIP archive in PATH_TO_UPLOADED_IMAGES and expands it
# then it converts the images to pyr tiffs and copies them to
# PATH_TO_PYR_IMAGES/ZIP_ARCHIVE_NAME without extension.
# The zip-file should be flat, only with the list of files
# A DoImage for each image will be created for every file,  and every record
# is updated (width, height, ecc) by a call to the image server

class ImageImportWorker
  include BackgroundFu::WorkerMonitoring

  # This is the main entry point, called by the background worker
  def process(args)
    @logger = Logger.new("#{Rails.root}/log/image_importer.log")

    t = Time.now
    @logger.info "Importer starting up: " + t.strftime("%m/%d/%Y") + t.strftime("at %I:%M%p")

    @doitem = nil
    @filegroup = nil
    @dodiv = nil

    record_progress(0, 100, "Starting...")

    #Magick goes here
    process_uploaded_file
  end


  # management of the uploaded image files.
  # It will scan the input directory for ZIP files, expand them and convert/add the images to the
  # Digital Objects.
  # this can be called from the console. It will create the pyr tiff images and insert them in the database
  # for all the images in a directory. The zip_file_name has to be ""
  # example:
  # process_uploaded_file( { :zip_file_name => "", :original_file_name => "CH_E_925_03" } )
  def process_uploaded_file()
    fcount = 0
    cur_count = 0
    @image_types  = [".jpg", ".jpeg",".tiff", ".tif", ".png", ".gif"]

    ####basedir = PATH_TO_UPLOADED_IMAGES #move to dropbox
    input_dirs = Dir.glob("#{PATH_TO_UPLOADED_IMAGES}/*")

    record_progress(1, 0, "Starting up...")

    if input_dirs.empty?
      @logger.debug "No uploaded dirs, exit"
      record_progress(0, 0, "No Uploaded dirs.")
      return
    end

    input_dirs.each do |cur_dir_path|

      @doitem = nil
      @filegroup = nil
      @dodiv = nil
      add_to_div = false

      cur_dir_name = File.basename(cur_dir_path)
      destination_path = "#{PATH_TO_PYR_IMAGES}/#{cur_dir_name}"

      if File.exist?(destination_path)
        @logger.error "Destination directory #{destination_path} exists, skip"
        next
      end


      # Move the input directory ti its destination
      FileUtils.mv(cur_dir_path, destination_path)

      @logger.debug "Moved dir #{cur_dir_path} to #{destination_path}"

      image_files = Dir.glob("#{destination_path}/*")

      @logger.debug "Dir has #{image_files.count} files."

      if image_files.count == 0
        @logger.error "Dir is empty! Skip."
        next
      end

      # If the image is a RISM id, automatically create the various DO items
      if cur_dir_name.match /[\d]{14,14}/
        @logger.debug "#{cur_dir_name} seems a RISM id"
        ms = Manuscript.find_by_rism_id(cur_dir_name)
        if ms
          @logger.debug "Manuscript #{ms.id} corresponds to RISM id #{cur_dir_name}"
          create_do_item(cur_dir_name)
          add_to_div = true
        else
          @logger.debug "No Manuscript found with that id."
        end
      end

      do_count = 0

      image_files.sort!

      image_files.each do |image|

        # Get the singular image name, without pyr_ and extension
        image_no_path = File.basename(image)
        image_no_pyr = image_no_path.gsub("pyr_", "")
        name = File.basename(image_no_pyr, File.extname(image_no_pyr))

        # Before processing, see if this file is already in the DB
        imgs = DoImage.find_by_page_name("#{cur_dir_name}/#{image_no_pyr}")
        if imgs != nil #exists, jump to next image in dir
          @logger.error "Image already in DB, skip."
          next
        end

        # creating the DB do_image
        image = DoImage.new
        image.file_name = "/#{cur_dir_name}/#{image_no_path}"
        image.page_name = "#{cur_dir_name}/#{image_no_pyr}"
        image.label = name
        image.file_type = "image"
        if image.update_infos
          image.save
          add_to_items(image, do_count) if add_to_div == true
        else
          @logger.error "Could not get the image info from tile server."
          record_progress(cur_count, fcount, "Could not get the image info from tile server")
          raise "Could not get the image info from tile server."
        end

        do_count = do_count + 2

      end

    end #input_dirs each

    @logger.info "Done import worker."
    record_progress(100, 100, "done.")
  end

  def create_do_item(rismid)
    @logger.debug "Creating relevant Do items for #{rismid}"
    @doitem = DoItem.find_by_rism_id(rismid)

    if !@doitem
      @logger.debug "Creating new DoItem: #{rismid}"
      @doitem = DoItem.create(:rism_id => rismid, :title => "DoItem form #{rismid}", :item_type => "Manuscript" )
    else
      @logger.debug "Adding to DoItem #{rismid}"
    end

    @filegroup = @doitem.do_file_groups.create(:title => "File Group Images for #{rismid}")
    @dodiv = @doitem.do_divs.create(:title => "Div Images for #{rismid}")

    @logger.debug "Created fg #{@filegroup.id}, div #{@dodiv.id} and item #{@doitem.id}"
  end

  def add_to_items(doimage, folder_max)
    dofile = DoFile.create(:title => doimage.page_name, :do_file_group_id => @filegroup.id, :do_image_id => doimage.id )

    divfile = DoDivFile.create(:do_file_id => dofile.id, :do_div_id => @dodiv.id, :file_order => folder_max)
    #@logger.debug "Created file #{dofile.id}, divfile #{divfile.id}"
  end


end
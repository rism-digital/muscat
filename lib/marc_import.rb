# Reads from a MARCXML file and imports the records into the database

require 'nokogiri'
require 'logger' 

class MarcImport
  
  # Initializes MarcImport Class instance
  # @param source_file [String] Filename
  # @param model [String] Model Name
  # @return [MarcImport] Instance
  def initialize(source_file, model, from = 0)
    #@log = Logger.new(Rails.root.join('log/', 'import.log'), 'daily')
    @from = from
    @source_file = source_file
    @model = model
    @total_records = open(source_file) { |f| f.grep(/001">/) }.size
    @import_results = Array.new
    @cnt = 0
    @start_time = Time.now
    
    # Load users, for source model
    @users = nil
    if File.exist?("link_users.yml") && @model == "Source"
      @users = YAML.load(File.read("link_users.yml"))
      puts "Read #{@users.count} users"
    else
      puts "No User file provided"
    end
    
    MarcConfigCache.get_configuration model.downcase
    MarcConfigCache.add_overlay(model, "#{Rails.root}/housekeeping/import/import_tags_source.yml") if @model == "Source"
  end

  # Helper method to parse huge files with nokogiri.
  # The block-parameter is used for the automatic Iteration and should not be set.
  # @param filename [String] Filename
  def each_record(filename, &block)
    File.open(filename) do |file|
      Nokogiri::XML::Reader.from_io(file).each do |node|
        if node.name == 'record' || node.name == 'marc:record' and node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
          yield(Nokogiri::XML(node.outer_xml).root)
        end
      end
    end
  end

  # Performs Import for the given Instance.
  # @return [String] Results 
  # @see #create_record
  def import
    each_record(@source_file) { |record|         
        rec = Nokogiri::XML(record.to_s)
        # Use external XSLT 1.0 file for converting to MARC21 text
        xslt  = Nokogiri::XSLT(File.read(Rails.root.join('housekeeping/import/', 'marcxml2marctxt_1.0.xsl')))
        marctext = CGI::unescapeHTML(xslt.transform(rec).to_s)
        create_record(marctext)
    }
    puts @import_results
  end

  # Creates a Record from a MarcXML String.
  # @param buffer [String] MarcXML
  def create_record(buffer)
    @cnt += 1
    #@total_records += 1
    buffer.gsub!(/[\r\n]+/, ' ')
    buffer.gsub!(/ (=[0-9]{3,3})/, "\n\\1")
    if @total_records >= @from
      marc = Object.const_get("Marc" + @model).new(buffer)
      # load the text source but without resolving externals
      marc.load_source(false)
      
      if marc.is_valid?(false)
       
        # step 1.  update or create a new object
        model = Object.const_get(@model).find_by_id(marc.get_id)
        if !model
          # @todo possibly unused variable "status"
          status = "created"
          if @model == "Catalogue"
            model = Object.const_get(@model).new(:id => marc.get_id, :name => marc.get_name, :author => marc.get_author, :revue_title=> marc.get_revue_title, :description => marc.get_description, :wf_owner => 1, :wf_stage => "published")

          elsif @model == "Person" || @model == "Institution"
            model = Object.const_get(@model).new(:id => marc.get_id, :wf_owner => 1, :wf_stage => "published")
          elsif @model == "Source"
            model = Object.const_get(@model).new(:id => marc.get_id, :lib_siglum => marc.get_siglum, :wf_owner => 1, :wf_stage => "published")
          end
        else
          status = "updated"
        end
        
        moddate = marc.first_occurance('005')
        if moddate && moddate.content
          begin
            date = DateTime.parse(moddate.content)
            updated_at = date if date
          rescue => e
            $stderr.puts "Cannot parse date for #{model.id}, #{moddate.content} #{e.message}"
          end
        end

        createdate = marc.first_occurance('008')
        if createdate && createdate.content
          begin
            date = DateTime.parse(createdate.content[0, 6])
            created_at = date if date
          rescue => e
            $stderr.puts "Cannot parse date for #{model.id}, #{createdate.content} #{e.message}"
          end
        end
        
        if updated_at && created_at
          if created_at < updated_at
            model.created_at = created_at
            model.updated_at = updated_at
          else
            $stderr.puts "created_at > updated_at #{created_at.to_s}, #{updated_at.to_s}, #{model.id}"
            model.created_at = created_at
            model.updated_at = created_at
          end
        elsif updated_at && !created_at ## the missing value will be date of import
          #$stderr.puts "No created_at for #{model.id}"
          model.updated_at = updated_at
        elsif !updated_at && created_at
          #$stderr.puts "No updated_at for #{model.id}"
          model.created_at = created_at
        else
          #$stderr.puts "No date information for #{model.id}"
        end
        
        # Make internal format
        marc.to_internal

        # step 2. do all the lookups and change marc fields to point to external entities (where applicable) 
        marc.suppress_scaffold_links
        marc.import
        
        # step 3. resolve external values if it is a source
        begin
          marc.root.resolve_externals if @model == "Source"
        rescue => e
          $stderr.puts
          $stderr.puts "Marc Import: Could not resolve externals on record".red
          $stderr.puts e.message.blue
          $stderr.puts "Record Id: #{model.id}".magenta
          $stderr.puts "#{marc.to_marc}"
        end
        
        # step 4. associate Marc to record
        model.marc = marc
        @import_results.concat( marc.results )
        @import_results = @import_results.uniq

        if @model == "Source"
          model.suppress_update_77x # we should not need to update the 774/773 relationships during the import
          model.suppress_update_count # Do not update the count for the foreign objects
          rt = marc.record_type
          if (rt)
            model.record_type = rt
          else
            "Empty record type for #{s.id}"
          end
        end
        
        model.suppress_reindex
        
        # In institution postpone the workgroup link creation
        model.suppress_update_workgroups if model.respond_to? :suppress_update_workgroups
        
        # Add user if exists, only for sources
        if @users && @model == "Source"
          if @users.include?(model.id.to_s)
            name = @users[model.id.to_s][:user]
            created_at = DateTime.parse(@users[model.id.to_s][:created_at])
            updated_at = DateTime.parse(@users[model.id.to_s][:updated_at])
            begin
              user = User.find_by_name(name)
              model.user = user
              model.created_at = created_at
              model.updated_at = updated_at
            rescue ActiveRecord::RecordNotFound
              puts "Could not find user #{name}".red
            end
          end
        end
        
        # step 5. insert model into database
        begin
          model.save! #
#          @log.info(@model+" record "+marc.get_id.to_s+" "+status)
#        rescue ActiveRecord::RecordNotUnique
#          @log.error(@model+" record "+marc.get_id.to_s+" import failed because record not unique")
        rescue => e
          $stderr.puts
          $stderr.puts "Marc Import: Could not save the imported record".red
          $stderr.puts e.message.blue
          $stderr.puts "Record Id: #{model.id}".magenta
          $stderr.puts "#{marc.to_marc}"
          #puts e.backtrace.join("\n")
        end
        print "\rStarted: " + @start_time.strftime("%Y-%m-%d %H:%M:%S").green + " -- Record #{@cnt} of #{@total_records} processed".yellow
        #puts "Last offset: #{@total_records}, Last "+@model+" RISM ID: #{marc.first_occurance('001').content}"
      else
        $stderr.puts "Marc is not valid! #{buffer}"
      end
    end
  end
end



# Reads from a MARCXML file and imports the records into the database

require 'nokogiri'
require 'logger' 

class MarcImport
  
  def initialize(source_file, model, from = 0)
    #@log = Logger.new(Rails.root.join('log/', 'import.log'), 'daily')
    @from = from
    @source_file = source_file
    @model = model
    @total_records = open(source_file) { |f| f.grep(/001">/) }.size
    @import_results = Array.new
    @cnt = 0
    @start_time = Time.now
    
    MarcConfigCache.get_configuration model.downcase
    MarcConfigCache.add_overlay(model, "#{Rails.root}/housekeeping/import/import_tags_source.yml")
  end

  #Helper method to parse huge files with nokogiri
  def each_record(filename, &block)
    File.open(filename) do |file|
      Nokogiri::XML::Reader.from_io(file).each do |node|
        if node.name == 'record' and node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
          yield(Nokogiri::XML(node.outer_xml).root)
        end
      end
    end
  end

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

  # see 337
  def apply_bush_fix(marc)
    
    if nodeid = marc.first_occurance("001")
      id = nodeid.content
    end
    
    if ["50000002", "50000003", "50000004", "50000005", "50000006", "50000007",
        "50000008", "50000009", "50000010", "50000011", "50000012", "50000013",
        "50000014"].include?(id)
    
        node = marc.first_occurance('110', "g")
        if node && node.content
          sigla = node.content
          node.content = sigla + "-duplicate"
          
          $stderr.puts "Modified sigla for #{id}".red
          $stderr.puts "New siga: #{node.content}".yellow
        end
    end
    
  end

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
        
        marcdate = marc.first_occurance('005')
        if marcdate && marcdate.content
          begin
            date = DateTime.parse(marcdate.content)
            model.updated_at = date if date
            model.created_at = date if date
          rescue ArgumentError
            $stderr.puts "Cannot parse date for #{model.id}, #{marcdate.content}"
          end
        end

        # Make internal format
        marc.to_internal

        if @model == "Institution"
          apply_bush_fix(marc)
        end

        # step 2. do all the lookups and change marc fields to point to external entities (where applicable) 
        marc.suppress_scaffold_links
        marc.import

        # step 3. associate Marc with Manuscript
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
        
         # step 4. insert model into database
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



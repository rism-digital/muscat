# Reads from a MARCXML file and imports the records into the database

require 'nokogiri'

class MarcImport
  
  def initialize(source_file, model, from = 0)
    @from = from
    @source_file = source_file
    @model = model
    @total_records = 0
    @import_results = Array.new
  end

  def import
    #line_number = 0
    doc   = Nokogiri::XML(File.read(@source_file))
    marcblock=doc.xpath("//record")
    marcblock.each do |record|
        rec=Nokogiri::XML(record.to_s)

        # Use external XSLT 1.0 file for converting to MARC21 text
        xslt  = Nokogiri::XSLT(File.read(Rails.root.join('housekeeping/import/', 'marcxml2marctxt_record.xsl')))
        marctext=xslt.transform(rec).to_s
        #print marctext
        create_record(marctext)    
      end
    puts @import_results
  end

  def create_record(buffer, line_number=0)
    @total_records += 1
    buffer.gsub!(/[\r\n]+/, ' ')
    buffer.gsub!(/ (=[0-9]{3,3})/, "\n\\1")
    if @total_records >= @from
      marc = Object.const_get("Marc"+@model).new(buffer)
      # load the text source but without resolving externals
      marc.load_source(false)
      if marc.is_valid?(false)
        #p marc.get_marc_source_id
        # step 1.  update or create a new object
        model = Object.const_get(@model).find_by_id( marc.get_marc_source_id )
        if !model
          if @model!="Source"
            model = Object.const_get(@model).new(:wf_owner => 1, :wf_stage => "published", :wf_audit => "approved")
          else
            model = Object.const_get(@model).new(:id => marc.get_id, :lib_siglum => marc.get_siglum, :wf_owner => 1, :wf_stage => "published", :wf_audit => "approved")
          end

        end
          
        # step 2. do all the lookups and change marc fields to point to external entities (where applicable) 
        marc.import

        # step 3. associate Marc with Manuscript
        model.marc = marc
        @import_results.concat( marc.results )
        @import_results = @import_results.uniq
        # step 4. insert model into database
        #model.suppress_update_77x # we should not need to update the 772/773 relationships during the import
        #model.suppress_create_incipit
        #model.suppress_create_incipit
        #model.suppress_reindex
        model.save #rescue puts "save failed"
        puts "Last offset: #{@total_records}, Last "+@model+" RISM ID: #{marc.first_occurance('001').content}"
      else
        puts "failed to import marc record leading up to line #{line_number}"
      end
    end
  end
end



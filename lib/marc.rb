# Marc is a toplevel MARC element, corresponding to what is found in the
# <tt>source</tt> field of a Source. In encapsulates a root MarcNode which in
# turn has as children all the subsequent nodes is the Marc record.
# TODO: Add String.intern to convert all tags to symbols

class Marc
  include ApplicationHelper
  include Comparable
  
##  attr_reader :all_foreign_associations
  attr_accessor :root, :results, :suppress_scaffold_links_trigger

  LANGUAGES = {
		'lat' => 'Latin',
		'eng' => 'English',
		'ita' => 'Italian',
		'ger' => 'German',
		'spa' => 'Spanish',
		'fre' => 'French',
		'sco' => 'Scots',
		'wel' => 'Welsh',
		'rus' => 'Russian'
  }

  public
  
  DOLLAR_STRING = "_DOLLAR_"
  
  def initialize(model, source = nil, user = nil)
    @root = MarcNode.new(model)
    @marc21 = Regexp.new('^[\=]([\d]{3,3})[\s]+(.*)$')
    @loaded = false
    @resolved = false
##    @all_foreign_associations = Hash.new
    @tag = nil
    @source = source
    @results = Array.new
    @model = model
    @marc_configuration = MarcConfigCache.get_configuration model
  end
  
  # Returns the root MarcNode
  def __get_root
    @root
  end
  
  def suppress_scaffold_links
    self.suppress_scaffold_links_trigger = true
    @root.suppress_scaffold_links
  end  
  
  # Returns a copy of this object an all of its references
  def deep_copy
    Marshal.load(Marshal.dump(self))
  end

  # After a Marc file is loaded an parsed, read all the foreign references
  # and link them. In case they do not exist they will be created (upon saving the manuscript). 
  def import(reindex = false, user = nil)
    @root.import(false, reindex, user)
  end
  
  # Creates a Marc object from the <tt>source</tt> field in the Source record
  def load_source( resolve = true )
    @source.each_line { |line| ingest_raw(line.sub(/[\s\r\n]+$/, '')) } if @source
    @loaded = true
    @source_id = first_occurance("001").content || nil rescue @source_id = nil
    # when importing we do not want to resolve externals since source has ext_id (and not db_id)
    @root.resolve_externals unless !resolve
  end
  
  def loaded
    return @loaded
  end
  
  # Read a line from a MARC record
  def ingest_raw(tag_line)
    if tag_line =~ @marc21
      parse_marc21 $1, $2
    end
  end
  
  def to_internal
    # Drop leader
    by_tags("000").each {|t| t.destroy_yourself}
     
    # Drop other unused tags
    by_tags("003").each {|t| t.destroy_yourself}
    by_tags("005").each {|t| t.destroy_yourself}
    by_tags("008").each {|t| t.destroy_yourself}
  end
  # TODO arguments should use parameters or keywords
  def to_external(updated_at = nil, versions = nil, holdings = false)
    # cataloguing agency
    _003_tag = first_occurance("003")
    if !_003_tag
      agency = MarcNode.new(@model, "003", RISM::AGENCY, "")
      @root.children.insert(get_insert_position("003"), agency)
    end
  
    if updated_at
      last_transcation = updated_at.strftime("%Y%m%d%H%M%S") + ".0"
      # 005 should not be there, if it is avoid duplicates
      _005_tag = first_occurance("005")
      if !_005_tag
        @root.children.insert(get_insert_position("003"),
            MarcNode.new(@model, "005", last_transcation, nil))
      end
    end
    by_tags("599").each {|t| t.destroy_yourself}
  end
  
  # Parse a MARC 21 line
  def parse_marc21(tag, data)
    # Warning! we are skipping the tag that are not included in MarcConfig
    # It would probably be wise to notify the user 
    if !@marc_configuration.has_tag? tag
      @results << "Tag #{tag} missing in the marc configuration"
      return
    end
    
    # control fields
    if @marc_configuration.is_tagless?(tag)
      if data =~ /^[\s]*(.+)$/
        content = $1
        tag_group = @root << MarcNode.new(@model, tag, content, nil)
      end
    # normal fields
    else
      indicator = nil
      if data =~ /^[\s]*([^$]*)([$].*)$/
        indicator = $1
        record = $2
      end
       #p indicator
       #p record
      tag_group = @root << MarcNode.new(@model, tag, nil, indicator)
      # iterate trough the subfields
      while record =~ /^[$]([\d\w]{1,1})([^$]*)(.*)$/
        subtag  = $1
        content = $2
        record  = $3
        
        content.gsub!(DOLLAR_STRING, "$")
      
        # missing subtag 
        @results << "Subfield #{tag} $#{subtag} missing in the marc configuration" if !@marc_configuration.has_subfield? tag, subtag
        
        subtag = tag_group << MarcNode.new(@model, subtag, content, nil)
      end
    end
  end

  # Load marc data from hash, handy for json reading
  # This function by default uses marc_node.import to
  # create the relations with the foreign object and create
  # them in the DB. It will also call a reindex on them
  def load_from_hash(hash, user: nil, resolve: true, dry_run: false)
    @root << MarcNode.new(@model, "000", hash['leader'], nil) if hash['leader']
    
    if hash['fields']
      grouped_tags = {}
      hash['fields'].each do |s|
        k = s.to_a[0][0]
        grouped_tags[k] = [] if !grouped_tags.has_key?(k)
        grouped_tags[k] << s
      end
      
      grouped_tags.keys.sort.each do |tag_key|
        grouped_tags[tag_key].each do |toplevel|
          toplevel.each_pair do |tag, field|
            if field.is_a?(Hash)
              ind = ""
              
              if !field.has_key?('ind1') || !field.has_key?('ind2')
                ind = @marc_configuration.get_default_indicator tag
              else
                ind = field['ind1'] + field['ind2']
                ind.gsub!(" ", "#")
              end
              
              tag_group = @root << MarcNode.new(@model, tag, nil, ind)
              field['subfields'].each do | pos |
                pos.each_pair do |code, value|
                  value.gsub!(DOLLAR_STRING, "$")
                  tag_group << MarcNode.new(@model, code, value.strip, nil)
                end
              end
            else
              @root << MarcNode.new(@model, tag, field, nil)
            end # field.is_a?(Hash)
          end # toplevel.each_pair
        end # grouped_tags[tag_key].each
      end # grouped_tags.keys.sort.each
      
    end # if hash['fields']
    
    @loaded = true
    import(true, user) if !dry_run # Import the data, ONLY when necessary
    @source = to_marc
    @source_id = first_occurance("001").content || nil rescue @source_id = nil
    # When importing externals are not resolved, do it here
    @root.resolve_externals if resolve
  end
  
  # Load marc data from an array (use for loading diff versions)
  def load_from_array(array_of_tags)
    @root = MarcNode.new(@model)
    array_of_tags.each do |t|
      @root << t
    end 
    @loaded = true
  end

  def load_from_xml(record)
    namespace = {'marc': "http://www.loc.gov/MARC21/slim"}
    leader = record.xpath("//marc:leader", namespace).first

    @root << MarcNode.new(@model, "000", leader.text, nil) if leader

    record.xpath("marc:controlfield", namespace).each do |control|
      tag = control[:tag]
      content = control.text
      @root << MarcNode.new(@model, tag, content, nil)
    end

    record.xpath("marc:datafield", namespace).each do |datafield|
      tag = datafield[:tag]

      # We need to emulate "normal" tag loading
      if !@marc_configuration.has_tag? tag
        puts"Tag #{tag} missing in the marc configuration"
        next
      end

      ind = datafield[:ind1] + datafield[:ind2]
      ind.gsub!(" ", "#")

      tag_group = @root << MarcNode.new(@model, tag, nil, ind)
      datafield.xpath("marc:subfield", namespace).each do |subfield|
        code = subfield[:code]
        value = subfield.text.gsub(DOLLAR_STRING, "$").gsub(/'/, "&apos;").unicode_normalize.gsub(/\u0098/, "").gsub(/\u009C/, "")

          #doc = doc.to_s.gsub(/'/, "&apos;").unicode_normalize
          #doc = doc.gsub(/\u0098/, "").gsub(/\u009C/, "")

        tag_group << MarcNode.new(@model, code, value.strip, nil)
      end
    end

    @loaded = true
    @source = to_marc
    @source_id = first_occurance("001").content || nil rescue @source_id = nil

  end

  def get_model
    return @model.to_s
  end
  
  def config
    return @marc_configuration
  end

	def superimpose_template(template_name = "default.marc")
		load_source unless @loaded
		
    template = self.class.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/#{@model}/#{template_name}")))
    template.load_source false
		
		template.all_tags.each do |tag|
			if !first_occurance(tag.tag)
		    new_tag = tag.deep_copy
		    pi = get_insert_position(tag.tag)
				root.children.insert(pi, new_tag)
			end
		end
	end

=begin
  # Get all the foreign fields for this Marc object. Foreign fields are the one referred by ext_id ($0) in the marc record
  def get_all_foreign_associations
    if @all_foreign_associations.empty?
      for child in @root.children
        if @marc_configuration.has_foreign_subfields(child.tag)
          if master = child.get_master_foreign_subfield
            master.set_foreign_object
            @all_foreign_associations[master.foreign_object.id] = master.foreign_object
          end
        end
      end
    end
    @all_foreign_associations
  end
=end

  def each_foreign_association(options = {}, &block)
    for child in @root.children
      if @marc_configuration.has_foreign_subfields(child.tag)
        next if options.include?(:foreign_links_only) && options[:foreign_links_only] && @marc_configuration.use_foreign_links?(child.tag) == false
        if master = child.get_master_foreign_subfield
          master.set_foreign_object
          #@all_foreign_associations[master.foreign_object.id] = master.foreign_object
          yield master.foreign_object, child.tag, child.get_relator_code
        end
      end
    end
  end

  def get_all_foreign_classes
    @marc_configuration.get_all_foreign_classes
  end

  # Test if the root element starts with =xxx where xxx are digits
  # Also check (and correct) zero padding for fields and subfield with zero-padding requirement (e.g., IDs)
  def is_valid?(pad = true)
    load_source unless @loaded
    begin
      # loop through all the children to check and correct the zero-padding
      for child in @root.children
        child.check_padding( child.tag, "" ) if pad
      end
      if @root.to_marc =~ /^=[\d]{3,3}.*/
        return true
      end
    rescue
      return false
    end
    return false
  end
  
  # Find the insert position of a tag. For marc fields they should be ascending
  def get_insert_position(tag)
    load_source unless @loaded
    insert_at = 0
    for child in @root.children
      break if child.tag > tag
      insert_at += 1
    end
    insert_at
  end
  
  # Return the ID from field 001
  def get_marc_source_id
    source_id = nil
    if node = first_occurance("001")
      source_id = node.content
    end
    return source_id
  end
    
  # Set the RISM ID in the 001 field
  def set_id(id)
    id_tag = first_occurance("001")
    if id_tag
      id_tag.content = id
      # puts @root.to_marc
    else
      save_at = 0
      index = 0
      for child in @root.children
        if child.tag == "000"
          save_at = index
        end
        index += 1
      end
      @root.add_at(MarcNode.new(@model, "001", id, nil), save_at + 1)
    end
  end
  
  def get_id
    rism_id = nil
    if node = first_occurance("001")
      rism_id = node.content
    end
    return rism_id.to_s # make sure it is ALWAYS a string!
  end
  
  # Return the parent of a manuscript. This need to be improved
  # Currently handles holding records, item in collection and previous edition
  # More than one case should not (cannot ?) happen in one manuscript
  # Otherwise it would be necessary to change this to a many-to-many relationship and 
  # have this handled in the create_links / destroy_links methods
  def get_parent
    parent = nil
    # holding record pointing to a collection
    if node = first_occurance("973")
      parent = node.foreign_object
    # item in collection
    elsif node = first_occurance("773", "w")
      parent = node.foreign_object
    end
  end
  
  # Check if the passed tag exists
  def has_tag?(tag)
    load_source unless @loaded
    for child in @root.children
      return true if child.tag == tag.to_s
    end
    return false
  end
  
  # Find the first occurrance of a tag, even if more than one is present
  def first_occurance(tag, subtag = "")
    load_source unless @loaded
    #TODO: MOVE ALL THIS TO MarcNode??
    for child in @root.children
      if child.tag == tag
        return child if subtag.empty?
        for grandchild in child.children
          return grandchild if grandchild.tag == subtag
        end
      end
    end
    return nil
  end
  
  # Block to iterate over a set of given tags (passed as array), with a subtag
  # and an optional subtag value to filter on.
  def by_tags_with_subtag(tag_names, subtag, subtag_content = "")
    all_tags = by_tags_with_order(tag_names)
    tags = Array.new
    for child in all_tags
      if subtag_content.empty? && !child.fetch_first_by_tag( subtag )
        tags << child
      elsif child.fetch_first_by_tag( subtag ) && child.fetch_first_by_tag( subtag ).content == subtag_content
        tags << child
      end
    end
    return tags
  end
  
  # Returns and array with all values in a list or tag/subtag
  def all_values_for_tags_with_subtag(tag_names, subtag)
    load_source unless @loaded
    values = Array.new
    for child in @root.children
      next if !tag_names.include?(child.tag)
      next if !child.fetch_first_by_tag( subtag )
      next if !child.fetch_first_by_tag( subtag ).content
      if child.fetch_first_by_tag( subtag ).content.is_a? String
        next if child.fetch_first_by_tag( subtag ).content.empty?
      end
      values << child.fetch_first_by_tag( subtag ).content
    end
    # Sort the return value
    # because the value is computed on the fist tag
    # so 300 $804 will come before 593 $801
    values.uniq.sort
  end
  
  def to_yaml
    load_source unless @loaded
    @root.to_yaml
  end   

  def to_marc
    load_source unless @loaded
    @root.to_marc
  end
  
  # Export as a valid MARC record
  def export
    load_source unless @loaded
    @root.to_marc :true    
  end
 
  def to_json
    load_source unless @loaded
    marc_json = {"leader" => "01471cjm a2200349 a 4500", "fields" => []}
    array = self.root.each{|c| c}
    array.each do |node|
      marc_json["fields"] << node.to_json
    end
    return marc_json
  end

  def to_xml(updated_at = nil, versions = nil, holdings = true)
    out = Array.new
    out << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    out << "<!-- Exported from RISM Digital (https://rism.digital/) Date: #{Time.now.utc} -->\n"
    out << "<marc:collection xmlns:marc=\"http://www.loc.gov/MARC21/slim\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd\">\n"
    out << to_xml_record(updated_at, versions, holdings)
    out << "</marc:collection>" 
    return out.join('')
  end
  
  def to_xml_record(updated_at, versions, holdings)
    load_source unless @loaded
    
    safe_marc = self.deep_copy
    safe_marc.root = @root.deep_copy
    safe_marc.to_external(updated_at, versions, holdings)
    
    out = String.new
    
    out += "\t<marc:record>\n"
    for child in safe_marc.root.children
      out += child.to_xml
    end

    out += "\t</marc:record>\n"
    
    return out
  end

  # Export a dump of the contents
  # just the text, as is
  def to_raw_text
    lines = []
    
    @source.each_line do |data|
      line = []
      if data =~ /^[\s]*([^$]*)([$].*)$/
        indicator = $1
        record = $2
      end
            
      while record =~ /^[$]([\d\w]{1,1})([^$]*)(.*)$/
        content = $2
        record  = $3
        
        line << content.gsub(DOLLAR_STRING, "$")
      end
      
      lines << line.join(" ")
    end
    
    lines.join("\n")
  end

  # Return all tags
  def all_tags( resolve = true )
    load_source( resolve ) unless @loaded
    tags = Array.new
    for child in @root.children
      tags << child
    end
    return tags
  end
  
  # Return all the tags with a given name
  def by_tags(tag_names)
    load_source unless @loaded
    tags = Array.new
    for child in @root.children
        tags << child if tag_names.include? child.tag
    end
    return tags
  end
  
  # Return an ordered list of the given tags
  def by_tags_with_order(tag_names)
    load_source unless @loaded
    tags = Array.new
    tag_names.each do |tag_name|
      tags += by_tags tag_name
    end
    return tags
  end

  
  def each_data_tags_present( no_control = true )
    load_source unless @loaded
    seen = Hash.new
    for child in @root.children
      unless (@marc_configuration.is_tagless? child.tag) && no_control
        seen[child.tag] = 1
      end
    end
    seen.keys.sort.each { |tag| yield tag }
  end

  def each_data_tag_from_tag(tag)
    load_source unless @loaded

    for child in @root.children
      if child.tag == tag
        yield child
      end
    end
  end

  def subfield(subfield_reference)
    load_source unless @loaded
    if subfield_reference.match /([\d]{3,3})([\w]{1,1})/
      tag = $1
      subfield = $2
      for child in @root.children
        if child.tag == tag
          for grandchild in child.children
            # puts grandchild.tag
            return grandchild.looked_up_content if grandchild.tag == subfield
          end
        end
      end
    end
    return nil
  end

  def each_by_tag(tag, &block)
    load_source unless @loaded
    @root.each_by_tag(tag, &block)
  end
  
  def each_by_tag_after(tag, node, &block)
    load_source unless @loaded
    @root.each_by_tag(tag, node, &block)
  end

  # Get the value of a tag, from the foreign object if necessary
  def get_real_value(parent, child)
    if @marc_configuration.is_foreign?(parent.tag, child.tag)
      child.set_foreign_object unless child.foreign_object
      #allfields[child.tag + grandchild.tag] = grandchild.looked_up_content
      value = child.looked_up_content
    else
      #allfields[child.tag + grandchild.tag] = grandchild.content
      value = child.content
    end
    if value
      return DictionaryOrder::normalize(value)
    else
      return nil
    end
  end

  def change_authority_links(old_auth, new_auth)
    return [] if old_auth.class != new_auth.class
    
    auth_model = old_auth.class.to_s
    
    # Get the tags to update
    rewrite_tags = @marc_configuration.get_remote_tags_for(auth_model)
    return [] if rewrite_tags.empty?
    
    changed_tags = []
    rewrite_tags.each do |rewrite_tag|
      master = @marc_configuration.get_master(rewrite_tag)
      
      each_by_tag(rewrite_tag) do |t|
        # Get the ID in the tag, print a warning if it is not there!
        marc_auth_id = t.fetch_first_by_tag(master)
        if !marc_auth_id || !marc_auth_id.content
          puts "#{ref.id} tag #{rtag} does not have subtag #{master}"
          next
        end
    
        # Skip if this link is to another auth file
        next if marc_auth_id.content.to_i != old_auth.id
        
        # We need to preserve the position of this tag
        # So we remove all the foreign elements from the tag
        # and just add there the new empty master
        t.all_children.each {|ch| ch.destroy_yourself if @marc_configuration.is_foreign?(t.tag, ch.tag)}
        
        t.add(MarcNode.new(auth_model.downcase, master, new_auth.id, nil))
        t.sort_alphabetically
        
        changed_tags << t.tag

      end
      
    end
    
    return changed_tags
  end

  def find_duplicates(tags = nil)
    tags_array = []

    if tags.is_a? String or tags.is_a? Integer
      tags_array = [tags.to_s]
    elsif tags.is_a? Array
      tags_array = tags
    else
      tags_array = each_data_tags_present(false){}.map
    end

    out_h = {}

    tags_array.sort.each do |t|
      tags = by_tags(t)
      dups = tags.sort.chunk_while {|i,j| i === j}.select { |e| e.size > 1 }
      next if dups.empty?
      out_h[t] = dups
    end

    return out_h
  end

  def deduplicate_tags!(tags_array = nil)
    output = {}
    dups_by_tag = find_duplicates(tags_array)

    dups_by_tag.each do |tag, dups|
      # the various duplicate tags get grouped together
      output[tag] = 0
      dups.each do |grp|
        # iterate over each tag except the first that we will preserve
        grp.drop(1).each do |marc_tag|
          # drop the others
          marc_tag.destroy_yourself
          output[tag] += 1
        end
      end
    end

    return output
  end

  def ==(other)
    load_source unless @loaded
    @source_id == other.get_marc_source_id
  end

  #TODO: This needs to compare the actual data hashes and not source_id
  #def ===(other)
  #  @source_id == other.get_marc_source_id
  #end

  def <=>(other)
    load_source unless @loaded
    @source_id.to_i <=> other.get_marc_source_id.to_i
  end

  alias to_s to_marc
  alias marc_source to_marc
  alias inspect to_marc
  
  private
  
  def marc_helper_get_008_language(value)
    # language is 35-37
    if value.length <= 35
      marc_get_range(value, value.length - 5, 3)
    else
      field = marc_get_range(value, 35, 3)
      if field
        field = field.to_s
      end
    end
    return field
  end
  
  # Get the first date from MARC 008
  def marc_helper_get_008_date1(value)
    # date1 is 07-10
    field = marc_get_range(value, 7, 4)
    if field
      field = field.to_i
    end
    return field
  end

  # Get the second date from MARC 008
  def marc_helper_get_008_date2(value)
    # date2 is 11-14
    field = marc_get_range(value, 11, 4)
    if field
      field = field.to_i
    end
    return field
  end
  
  def marc_helper_get_008_language(value)
    codes = Array.new
    
    forward = {
    	'lat' => 'Latin',
    	'la' => 'Latin',

    	'eng' => 'English',
    	'en' => 'English',

    	'ita' => 'Italian',
    	'it' => 'Italian',

    	'ger' => 'German',
    	'ge' => 'German',

    	'spa' => 'Spanish',
    	'sp' => 'Spanish',

    	'fre' => 'French',
    	'fr' => 'French',

    	'sco' => 'Scots',
    	'sc' => 'Scots',

    	'wel' => 'Welsh',
    	'we' => 'Welsh',

    	'rus' => 'Russian',
    	'ru' => 'Russian'
    }

    reverse = {
    	'Latin'   => 'lat',
    	'English' => 'eng',
    	'Italian' => 'ita',
    	'German'  => 'ger',
    	'Spanish' => 'spa',
    	'French'  => 'fre',
    	'Scots'   => 'sco',
    	'Welsh'   => 'wel',
    	'Russian' => 'rus'
    }

    if value =~ /^[^|]+[|]+([^|]+).+$/
      if forward.has_key?($1)
        codes << forward[$1]
        codes << reverse[forward[$1]]
      end
    end

    return codes
  end
  
  # Return the string from the given start for lenght in a 008 MARC record
  def marc_get_range(value, start, length)
    if value.length <= start
      return nil
    end
    field = value[start, length]
    if field.match(/x+/i)
      return nil
    end
    return field
  end
  
  def marc_create_pae_entry(conf_tag, conf_properties, marc, model)
    out = []
   
    tag = conf_properties && conf_properties.has_key?(:from_tag) ? conf_properties[:from_tag] : nil
    
    return if tag == nil
    return if tag != "031"
    
    marc.each_by_tag(tag) do |marctag|
      subtags = [:a, :b, :c, :g, :n, :o, :p]
      vals = {}
      
      subtags.each do |st|
        v = marctag.fetch_first_by_tag(st)
        vals[st] = v && v.content ? v.content : "0"
      end

      next if vals[:p] == "0"

      pae_nr = "#{vals[:a]}.#{vals[:b]}.#{vals[:c]}"

      # FIXME a bit ugly here
      # SEE #860
      # Timesigs can be fractions, and a division by 0
      # will bomb solr.
      # This will also be done in solr

      if vals[:o].split("/").count > 1
        # Set it to C, time is ignored anyways 
        vals[:o] = "c" if vals[:o].split("/")[1].to_i == 0
      end

      s = "@start:#{pae_nr}\n";
	    s << "@clef:#{vals[:g]}\n";
	    s << "@keysig:#{vals[:n]}\n";
	    s << "@key:\n";
	    s << "@timesig:#{vals[:o]}\n";
	    s << "@data:#{vals[:p]}\n";
	    s << "@end:#{pae_nr}\n"

      out << s
    end

    return out
    
  end
  
  def marc_create_aggregated_text(conf_tag, conf_properties, marc, model)
    out = []
    tags = conf_properties && conf_properties.has_key?(:tags) ? conf_properties[:tags] : nil
    
    return if tags == nil
    return if !tags.is_a?(Hash)
    
    tags.each do |tag, subtag|
      marc.each_by_tag(tag) do |marctag|
        marctag.each_by_tag(subtag) do |marcsubtag|
          #puts "#{tag}, #{subtag}"
          out << marcsubtag.content if marcsubtag.content
          
        end
      end
    end
    
    return out
  end
	
  def marc_extract_publisher(conf_tag, conf_properties, marc, model)
    out = []

    ["700", "710"].each do |tag, subtag|
      marc.each_by_tag(tag) do |marctag|
        code = marctag.fetch_first_by_tag("4")
        if code && code.content && code.content == "pbl"
          name = marctag.fetch_first_by_tag("a")
          out << name.content if name && name.content
        end
      end
    end
    
    return out
  end

  def marc_extract_dates(conf_tag, conf_properties, marc, model)
    out = []
    tag = conf_properties && conf_properties.has_key?(:from_tag) ? conf_properties[:from_tag] : nil
    subtag = conf_properties && conf_properties.has_key?(:from_subtag) ? conf_properties[:from_subtag] : nil

    return if tag == nil
    return if subtag == nil

    marc.each_by_tag(tag) do |marctag|
      marctag.each_by_tag(subtag) do |marcsubtag|
        out.concat(date_to_array(marcsubtag.content)) if marcsubtag && marcsubtag.content
      end
    end
    
    # are we part of a collection? Or have a parent?
    if model.source_id
      parent = Source.find(model.source_id)
      parent.marc.load_source false
      parent.marc.each_by_tag(tag) do |marctag|
        marctag.each_by_tag(subtag) do |marcsubtag|
          out.concat(date_to_array(marcsubtag.content)) if marcsubtag && marcsubtag.content
        end
      end
    end
    
    return out.sort.uniq
  end
  
  def marc_index_774_field(conf_tag, conf_properties, marc, model)
    out = []

    marc.each_by_tag("774") do |marctag|
      id_tag = marctag.fetch_first_by_tag("w")
      next if !id_tag || !id_tag.content

      id = id_tag.content

      code = marctag.fetch_first_by_tag("4")
      if code && code.content && code.content == "holding"
        hodl = marctag.fetch_first_by_tag("a")
        holding = model.get_collection_holding(id.to_i)
        out << holding.source.id.to_s if holding && holding.source
      else
        out << id
      end
    end
    
    return out
  end

  # Get the birth date from MARC 100$d
  def marc_helper_get_birthdate(value)
    if value.include?('-')
      field = value.split('-')[0]
    end
    if field
      field = field.to_i
    end
    return field
  end

  # Get the death date from MARC 100$d
  def marc_helper_get_deathdate(value)
    if value.include?('-')
      field = value.split('-')[1]
    end
    if field
      field = field.to_i
    end
    return field
  end

  def marc_index_make_024_person(conf_tag, conf_properties, marc, model)
    out = []
    marc.each_by_tag("024") do |marctag|
      id_tag = marctag.fetch_first_by_tag("a")
      next if !id_tag || !id_tag.content

      type_tag = marctag.fetch_first_by_tag("2")
      next if !type_tag || !type_tag.content

      out << "#{type_tag.content}:#{id_tag.content}"
    end

    return out
  end

end
 


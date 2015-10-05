# Marc is a toplevel MARC element, corresponding to what is found in the
# <tt>source</tt> field of a Source. In encapsulates a root MarcNode which in
# turn has as children all the subsequent nodes is the Marc record.
# TODO: Add String.intern to convert all tags to symbols

class Marc
  include ApplicationHelper
  include Comparable
  
  attr_reader :all_foreign_associations
  attr_accessor :root, :results

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
    @all_foreign_associations = Hash.new
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
  
  # Returns a copy of this object an all of its references
  def deep_copy
    Marshal.load(Marshal.dump(self))
  end

  # After a Marc file is loaded an parsed, read all the foreign references
  # and link them. In case they do not exist they will be created (upon saving the manuscript). 
  def import(reindex = false, user = nil)
    @all_foreign_associations = @root.import(false, reindex, user)
  end
  
  # Creates a Marc object from the <tt>source</tt> field in the Source record
  def load_source( resolve = true )
    @source.each_line { |line| ingest_raw(line.sub(/[\s\r\n]+$/, '')) } if @source
    @loaded = true
    @source_id = first_occurance("001").content || nil rescue @source_id = nil
    # when importing we do not want to resolve externals since source has ext_id (and not db_id)
    @root.resolve_externals unless !resolve
  end
  
  # Read a line from a MARC record
  def ingest_raw(tag_line)
    if tag_line =~ @marc21
      parse_marc21 $1, $2
    end
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
    if @marc_configuration.is_tagless? tag
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
  def load_from_hash(hash, user = nil, resolve = true)
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
                  tag_group << MarcNode.new(@model, code, value, nil)
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
    import(true, user) # Import
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

  def get_model
    return @model.to_s
  end
  
  def config
    return @marc_configuration
  end

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

  # Return the MARC leader
  def get_leader
    control000 = first_occurance("000").content || "" rescue control000 = ""
  end
  
  # Fin the insert position of a tag. For march fields they should be ascending
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
  # Currently handles holding records, item in collection/convolutum and previous edition
  # More than one case should not (cannot ?) happen in one manuscript
  # Otherwise it would be necessary to change this to a many-to-many relationship and 
  # have this handled in the create_links / destroy_links methods
  def get_parent
    parent = nil
    # holding record
    if node = first_occurance("004")
      parent = node.foreign_object
    # item in collection
    elsif node = first_occurance("773", "w")
      parent = node.foreign_object
    # previous edition
    elsif node = first_occurance("775", "w")
      parent = node.foreign_object
    end
  end
  
  # Copied from application helpers
  # Used for the inventory database to tuncate the title 
  def pretty_truncate(text, length = 30, truncate_string = " ...")
    return if text.nil?
    l = length - truncate_string.mb_chars.length
    text.mb_chars.length > length ? text[/\A.{#{l}}\w*\;?/m][/.*[\w\;]/m] + truncate_string : text
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
    load_source unless @loaded
    tags = Array.new
    for child in @root.children
      next if !tag_names.include?(child.tag)
      if subtag_content.empty? && !child.fetch_first_by_tag( subtag )
        tags << child
      elsif child.fetch_first_by_tag( subtag ) && child.fetch_first_by_tag( subtag ).content == subtag_content
        tags << child
      end
      #for grandchild in child.children
      #  tags 
      #  tags << child if grandchild.tag == subtag && grandchild.content == subtag_content
      #end
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
      next if child.fetch_first_by_tag( subtag ).content.empty?
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
  
  def to_xml(updated_at = nil, versions = nil)
    out = Array.new
    out << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    out << "<!-- Exported from RISM CH (http://www.rism-ch.org/) Date: #{Time.now.utc} -->\n"
    out << "<marc:collection xmlns:marc=\"http://www.loc.gov/MARC21/slim\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd\">\n"
    out << to_xml_record(updated_at, versions)
    out << "</marc:collection>" 
    return out.join('')
  end
  
  def to_xml_record(updated_at, versions)
    load_source unless @loaded
    
    safe_root = @root.deep_copy
    
    # Since we are on a copy of @root
    # if we add a 005 tag get_insert_position in the
    # subsequent calls will return an incorrect value
    # since it does not have the new tag. Keep an offset
    # and pad it
    offset = 0
    
    if updated_at
      last_transcation = updated_at.strftime("%Y%m%d%H%M%S") + ".0"
      # 005 should not be there, if it is avoid duplicates
      _005_tag = first_occurance("005")
      if !_005_tag
        safe_root.add_at(MarcNode.new(@model, "005", last_transcation, nil), get_insert_position("005") )
        offset += 1
      end
    end
    
    # This is not the best place to do this
    # But until we refactor MARC it is ok here
    if versions
      versions.each do |v|
        author = v.whodunnit != nil ? "#{v.whodunnit}, " : ""
        entry = "#{author}#{v.created_at} (#{v.event})"
        n599 = MarcNode.new(@model, "599", "", nil)
        n599.add_at(MarcNode.new(@model, "a", entry, nil), 0)
        safe_root.add_at(n599, get_insert_position("599") + offset)
      end
        
    end
    
    out = String.new
    
    out += "\t<marc:record>\n"
    for child in safe_root.children
      out += child.to_xml
    end

    out += "\t</marc:record>\n"
    
    return out
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
      
      s = "@start:#{pae_nr}\n";
	    s = s + "@clef:#{vals[:g]}\n";
	    s = s + "@keysig:#{vals[:n]}\n";
	    s = s + "@key:\n";
	    s = s + "@timesig:#{vals[:o]}\n";
	    s = s + "@data:#{vals[:p]}\n";
	    s = s + "@end:#{pae_nr}\n"

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

end
 


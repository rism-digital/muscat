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
  
  def initialize(model, source = nil)
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
  def import
    @all_foreign_associations = @root.import
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
  def load_from_hash(hash, resolve = true)
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
    import
    @source = to_marc
    @source_id = first_occurance("001").content || nil rescue @source_id = nil
    # when importing we do not want to resolve externals since source has ext_id (and not db_id)
    @root.resolve_externals unless !resolve
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
  
  # Update the last transaction field, 005.
  def update_005
    last_transcation = Time.now.utc.strftime("%Y%m%d%H%M%S") + ".0"
    _005_tag = first_occurance("005")
    if _005_tag
      _005_tag.content = last_transcation
    else
      @root.add_at(MarcNode.new(@model, "005", last_transcation, nil), get_insert_position("005") )
    end
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
      @root.add_at(MarcNode.new(@model, "001",_id, nil), save_at + 1)
    end
  end
  
  def get_id
    rism_id = nil
    if node = first_occurance("001")
      rism_id = node.content
    end
    return rism_id
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
  
  def export_xml
    load_source unless @loaded
    out = String.new
    out += "\t<marc:record>\n"
    for child in @root.children
      out += child.to_xml
    end
    # @root.to_xml
    out += "\t</marc:record>\n"
    return out
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

=begin
  # Index the fields in this MARC element with Ferret
  def index(special_fields)
    # NOTE :index_helper is ONLY for tags 000-008
    # Data tags 010+ must use :ceded_index_helper to which the entire tag (reference) is sent not just the subfield value

    load_source unless @loaded
    
    # Now handled by the daemons' write() method
    # REMOTE_INDEX.delete id
    
    ceded = Hash.new
    if RISM::INCIPIT_STRATEGY == "Incipit031"
      ceded[:p_field] = Array.new
    else
      ceded[:h_field] = Array.new
    end
    ceded[:index_keys] = Array.new
    ceded[:index_x4_ngrams] = Array.new
    ceded[:index_x5_ngrams] = Array.new
    ceded[:index_x6_ngrams] = Array.new
    ceded[:index_x4_noz_ngrams] = Array.new
    ceded[:index_x5_noz_ngrams] = Array.new
    ceded[:index_x6_noz_ngrams] = Array.new
    
    allfields = Hash.new
    group_collect = Hash.new
    for child in @root.children

      if child.has_children?
        for grandchild in child.children
          if IndexConfig.is_indexable?(child.tag, grandchild.tag)
            
            if IndexConfig.has_helper?(child.tag, grandchild.tag)              
              tokens = run_helper(IndexConfig.get_helper(child.tag, grandchild.tag), child)
              if tokens.is_a? Hash
                tokens.each do |key, grouping|
                  # p key 
                  # p "xxxxxx"
                  # p grouping
                  if grouping
                    grouping.each do |value|
                      ceded[key] << value unless value.empty? or ceded[key].include?(value)
                    end
                  end
                end
              else
                group_collect.merge!(tokens) if tokens and not tokens.empty?
              end
            else
              unless group_collect.has_key? child.tag + grandchild.tag
                group_collect[child.tag + grandchild.tag] = Array.new
              end

              group_collect[child.tag + grandchild.tag] << get_real_value(child, grandchild)
            end
          end
        end

      else

        if IndexConfig.is_indexable?(child.tag, '')      
          value = child.content
          
          if IndexConfig.has_helper?(child.tag, '')
            tokens = run_helper(IndexConfig.get_helper(child.tag, ''), value)
            group_collect.merge!(tokens)
          else
            
            unless group_collect.has_key? child.tag
              group_collect[child.tag] = Array.new
            end
            
            group_collect[child.tag] << DictionaryOrder::normalize(value)
          
          end
        end
      end
    end

    group_collect.each do |key, group|
      allfields[key.intern] = group#.join(" ")
    end
    
    allfields[:id] = special_fields[:id].to_s
    special_fields.each { |key, value| allfields[key] = value unless key == :id }
    
    if RISM::INCIPIT_STRATEGY == "Incipit031"
      allfields[:"031p"] = ceded[:p_field] unless ceded[:p_field] and ceded[:p_field].empty?
    else
      allfields[:"789h"] = ceded[:h_field] unless ceded[:h_field] and ceded[:h_field].empty?      
    end
    allfields[:keys] = ceded[:index_keys] unless ceded[:index_keys].empty?    
    allfields[:ngramsx4] = ceded[:index_x4_ngrams] unless ceded[:index_x4_ngrams].empty?
    allfields[:ngramsx5] = ceded[:index_x5_ngrams] unless ceded[:index_x5_ngrams].empty?
    allfields[:ngramsx6] = ceded[:index_x6_ngrams] unless ceded[:index_x6_ngrams].empty?
    allfields[:ngramsx4noz] = ceded[:index_x4_noz_ngrams] unless ceded[:index_x4_noz_ngrams].empty?
    allfields[:ngramsx5noz] = ceded[:index_x5_noz_ngrams] unless ceded[:index_x5_noz_ngrams].empty?
    allfields[:ngramsx6noz] = ceded[:index_x6_noz_ngrams] unless ceded[:index_x6_noz_ngrams].empty?
      
    #puts allfields.to_yaml  
    REMOTE_INDEX.write(allfields)

  end
=end

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
  
end
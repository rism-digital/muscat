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
  
  def initialize(source = nil)
    @root = MarcNode.new
    @marc21 = Regexp.new('^[\=]([\d]{3,3})[\s]+(.*)$')
    @loaded = false
    @resolved = false
    @all_foreign_associations = Hash.new
    @tag = nil
    @source = source
    @results = Array.new
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
    if !MarcConfig.has_tag? tag
      @results << "Tag #{tag} missing in the marc configuration"
      return
    end
    
    # control fields
    if MarcConfig.is_tagless? tag
      if data =~ /^[\s]*(.+)$/
        content = $1
        tag_group = @root << MarcNode.new(tag, content, nil)
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
      tag_group = @root << MarcNode.new(tag, nil, indicator)
      # iterate trough the subfields
      while record =~ /^[$]([\d\w]{1,1})([^$]*)(.*)$/
        subtag  = $1
        content = $2
        record  = $3
        
        content.gsub!(DOLLAR_STRING, "$")
      
        # missing subtag 
        @results << "Subfield #{tag} $#{subtag} missing in the marc configuration" if !MarcConfig.has_subfield? tag, subtag
        
        subtag = tag_group << MarcNode.new(subtag, content, nil)
      end
    end
  end

  # Get all the foreign fields for this Marc object. Foreign fields are the one referred by ext_id ($0) in the marc record
  def get_all_foreign_associations
    if @all_foreign_associations.empty?
      for child in @root.children
        if MarcConfig.has_foreign_subfields(child.tag)
          if master = child.get_master_foreign_subfield
            master.set_foreign_object
            @all_foreign_associations[master.foreign_object.ext_id] = master.foreign_object
          end
        end
      end
    end
    @all_foreign_associations
  end

  # Test if the root element starts with =xxx where xxx are digits
  # Also check (and correct) zero padding for fields and subfield with zero-padding requirement (e.g., IDs)
  def is_valid?
    load_source unless @loaded
    begin
      # loop through all the children to check and correct the zero-padding
      for child in @root.children
        child.check_padding( child.tag, "" )
      end
      if @root.to_marc =~ /^=[\d]{3,3}.*/
        return true
      end
    rescue
      return false
    end
    return false
  end

  # Get the std_title and std_title_d values
  def get_std_title  
    std_title = ""
    std_title_d = ""
    
    # try to get the title (130)
    node = first_occurance("130", "a")
    # get 240 if nothing or PSMD
    if !node || RISM::BASE == "pr"
      node = first_occurance("240", "a")
    end
    # get 245 if INVENTORIES
    if RISM::BASE == "in"
      node = first_occurance("245", "a")
    end
    standard_title = node.foreign_object if node 
   
    # we found one
    if standard_title
      # specific for inventories
      if RISM::BASE == "in"
        std_title = pretty_truncate(standard_title.title, 50)
        std_title_d = DictionaryOrder::normalize(std_title)
      else
        std_title = standard_title.title
        std_title_d = standard_title.title_d
      end
    # or not
    else
      if is_convolutum?
        std_title = "[Convolutum]"  
        std_title_d = '+'      
      elsif is_holding?
        std_title = "[Holding]"  
        std_title_d = '+' 
      else
        std_title = "[Collection]"
        std_title_d = '-' 
      end
    end
    
    [std_title, std_title_d]
  end
  
  # Get the composer and composer_d values
  def get_composer
    composer = ""
    composer_d = ""

    if node = first_occurance("100", "a")
      person = node.foreign_object
      composer = person.full_name
      composer_d = person.full_name_d
    end
    
    [composer, composer_d]
  end
  
  # Get the Library and shelfmarc for a MARC record
  def get_siglum_and_ms_no
    siglum = "" 
    ms_no = ""
    

    tags_852 = by_tags(["852"])    
    if tags_852.length > 1 # we have multiple copies
      tags_852.each do |tag|
        a_tag = tag.fetch_first_by_tag("a").content
        siglum = siglum == "" ? "#{a_tag}" : "#{siglum}, #{a_tag}"
      end
      #siglum = "[multiple copies]"
      ms_no = "[multiple copies]"
          
    elsif tags_852.length == 1 # single copy
      if node = first_occurance("852", "a")
        siglum = node.foreign_object.siglum
      end
      if node = first_occurance("852", "p")
        ms_no = node.content
      end
    end
    
    return [siglum, ms_no]
  end
  
  # On RISM A/1 ms_no contains the OLD RISM ID, get it from 035
  def get_book_rism_id
    if node = first_occurance("035", "a")
      return node.content
    end
  end
  
  # For bibliographic records, set the ms_title and ms_title_d field fromMARC 245 or 246
  def get_ms_title
    ms_title = "[unset]"  
    ms_title_field = (RISM::BASE == "in") ? "246" : "245" # one day the ms_title field (and std_title field) should be put in the environmnent.rb file
    if node = first_occurance(ms_title_field, "a")
      ms_title = node.content
    end
    
    # Special quirk for a-1
    # Reprints not always have 245 set, so we copied the 245 from the parent
    # into the 246. Since only reprints have 246, we can safely copy it from
    # there so it shows the [previous entry:] tag.
    # Quirky because it will re-read the marc data
    if RISM::BASE == "a1"
      if node = first_occurance("246", "a")
        ms_title = node.content
      end
    end
    
    ms_title_d = DictionaryOrder::normalize(ms_title)
   
    return [ms_title, ms_title_d]
  end
  
  # For holding records, set the condition and the urls (aliases)
  def get_ms_condition_and_urls
    ms_condition = "" 
    urls = ""
    image_urls = ""
    
    tag_852 = first_occurance( "852" )
    if tag_852
      q_tag = tag_852.fetch_first_by_tag("q")
      ms_condition = q_tag.content if q_tag
    
      url_tags = tag_852.fetch_all_by_tag("u")
      url_tags.each do |u|
        image_urls += "#{u.content}\n"
      end
      
      url_tags = tag_852.fetch_all_by_tag("z")
      url_tags.each do |u|
        urls += "#{u.content}\n"
      end
      
    end
    
    return [ms_condition, urls, image_urls]
  end
  
  # Set miscallaneous values
  def get_miscellaneous_values
    
    # In a1 is only in 033
    if RISM::BASE == "a1"
      language = "Unknown"
      date_from = nil
      date_to = nil

      # Try to extract all the text from 260
      if node = first_occurance("260")
        tag = node.fetch_first_by_tag(:c)
        if tag && tag.content
          toks = tag.content.split(/(\d+)/)
          first = true
          toks.each do |tk|
            next if tk.to_i == 0
            
            if first          
              date_from = tk.to_i
              first = false
            else
              date_to = tk.to_i
            end
            
          end
        end
      end
      return [language, date_from, date_to]
      
    else
      #FIXME!!! move to 033 for others?
      language = "Unknown"
      date_from = nil
      date_to = nil

      if node = first_occurance("008")
        unless node.content.empty?
          language = LANGUAGES[marc_helper_get_008_language(node.content)] || "Unknown"
          date_from = marc_helper_get_008_date1(node.content) || nil
          date_to = marc_helper_get_008_date2(node.content) || nil
        end
      end

      return [language, date_from, date_to]
    end
    
  end
  
  # Return if the MARC leader matches npd, i.e. convolutum
  def is_convolutum?
    return false unless get_leader.match(/^.....npd.*$/i)
    return true
  end

  # Return if the MARC leader matches nu, i.e. holding
  def is_holding?
    return false unless get_leader.match(/^.....nu.*$/i)
    return true
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
  def get_source_id
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
      @root.add_at(MarcNode.new("005", last_transcation, nil), get_insert_position("005") )
    end
  end
  
  # If this manuscript is linked with another via 772/773, update if it is our parent
  def update_77x
    # copy & pasted for now
    if (RISM::BASE == "pr")
      
      # See if we have a 1st relation in the 775
      parent_tags = by_tags_with_subtag("775", "4", "1st")
      return if parent_tags.count == 0 # no, return
      
      # We should NOT have more than one 775 1st tag, in every case
      # we will get only the fist and ignore the eventual others
      parent_manuscript_id = parent_tags[0].fetch_first_by_tag(:w)
      # puts parent_manuscript_id
      return if !parent_manuscript_id
      parent_manuscript = Source.find_by_ext_id(parent_manuscript_id.content)
      return if !parent_manuscript
      
      # check if the 775 tag already exists in the parent
      parent_manuscript.marc.each_data_tag_from_tag("775") do |tag|
        subfield = tag.fetch_first_by_tag("w")
        return if subfield && subfield.content == get_ext_id
      end
      # nothing found, add it in the parent manuscript
      _775_w = MarcNode.new("775", "", MarcConfig.get_default_indicator("775"))
      _775_w.add_at(MarcNode.new("w", get_ext_id, nil), 0 )
      _775_w.add_at(MarcNode.new("4", "led", nil), 1 )
      parent_manuscript.marc.root.add_at(_775_w, parent_manuscript.marc.get_insert_position("775") )
      parent_manuscript.suppress_create_incipit
      parent_manuscript.suppress_update_77x
      parent_manuscript.save
    else
      # do we have a parent manuscript?
      parent_manuscript_id = first_occurance("773", "w")
      return if !parent_manuscript_id
      parent_manuscript = Source.find_by_ext_id(parent_manuscript_id.content)
      return if !parent_manuscript
      # check if the 772 tag already exists
      parent_manuscript.marc.each_data_tag_from_tag("772") do |tag|
        subfield = tag.fetch_first_by_tag("w")
        return if subfield && subfield.content == get_ext_id
      end
      # nothing found, add it in the parent manuscript
      _772_w = MarcNode.new("772", "", MarcConfig.get_default_indicator("772"))
      _772_w.add_at(MarcNode.new("w", get_ext_id, nil), 0 )
      parent_manuscript.marc.root.add_at(_772_w, parent_manuscript.marc.get_insert_position("772") )
      parent_manuscript.suppress_create_incipit
      parent_manuscript.suppress_update_77x
      parent_manuscript.save
    end
    return
  end

  # Set the RISM ID in the 001 field
  def set_ext_id(ext_id)
    ext_id_tag = first_occurance("001")
    if ext_id_tag
      ext_id_tag.content = ext_id
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
      @root.add_at(MarcNode.new("001", ext_id, nil), save_at + 1)
    end
  end
  
  def get_ext_id
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
      unless (MarcConfig.is_tagless? child.tag) && no_control
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
    if MarcConfig.is_foreign?(parent.tag, child.tag)
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
    @source_id == other.get_source_id
  end

  #TODO: This needs to compare the actual data hashes and not source_id
  #def ===(other)
  #  @source_id == other.get_source_id
  #end

  def <=>(other)
    load_source unless @loaded
    @source_id.to_i <=> other.get_source_id.to_i
  end
  
  alias to_s to_marc
  alias source to_marc
  
end
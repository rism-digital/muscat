# A MarcNode represents a marc tag or subtag

class MarcNode

  include Enumerable
  attr_reader :tag, :content, :indicator, :foreign_object, :parent, :diff, :diff_is_deleted, :model
  attr_writer :tag, :content, :indicator, :foreign_object, :foreign_field, :diff, :diff_is_deleted
  attr_accessor :foreign_host, :suppress_scaffold_links_trigger
  
  def initialize(model, tag = nil, content = nil, indicator = nil)
    @tag = tag
    @content = content
    @indicator = indicator
    @parent = nil if tag == nil
    @children = []
    @foreign_object = nil
    @foreign_field = nil
    @foreign_host = false
    @diff = nil
    @diff_is_deleted = false
    # FIX We should have some sort of type checking here
    #raise "Model does not exit in enviroment" if !ActiveRecord::Base.descendants.map(&:name).include?(model.to_s.capitalize)
    @model = model
    @marc_configuration = MarcConfigCache.get_configuration @model

    # This is used during import of records
    # Muscat will try to always create the missing links, as default using
    # the master (generally $0) field, and fail if there is a problem.
    # This is the default behaviour.
    # In some case it is useful to try again using other fields, so this global
    # variable can be set to FALSE (remember, default is true!).
    @force_marc_creation = defined?(:MARC_FORCE_CREATION) ? $MARC_FORCE_CREATION : true
  end
  
  def suppress_scaffold_links
    self.suppress_scaffold_links_trigger = true
  end  
  
  # Returns a copy of this object an all of its references
  def deep_copy
    Marshal.load(Marshal.dump(self))
  end
  
  # Try to get the external references for this object
  def resolve_externals
    # Do nothing if the master tag is missing but optional
    if self.tag && @marc_configuration.master_optional?(self.tag)
      master = get_master_foreign_subfield
      return if !master
    end
    if parent == nil
      @children.each do |child|
        child.resolve_externals
      end
    else
      if @marc_configuration.has_foreign_subfields(self.tag) #&& @children.find{ |t| t.tag == "_" }
        #if !master = get_master_foreign_subfield
        #  # the master tag is missing in the source - this is the case when data was submitted from the editor
        #  master = add(MarcNode.new( @marc_configuration.get_master( self.tag ) , "", nil))
        #end
        master = get_master_foreign_subfield
        
        if !master

          # Try to fetch the 001 value for this element
          object_id = "Unknown"
          if @parent
            n = @parent.fetch_first_by_tag("001")
            if n && n.content
              object_id = n.content
            end
          end
              
          #raise NoMethodError, "Tag #{self.tag}: missing master (expected in $#{@marc_configuration.get_master( self.tag )}), tag contents: #{self.to_marc} "
          $stderr.puts "[#{@model} #{object_id}] Tag #{self.tag}: missing master (expected in $#{@marc_configuration.get_master( self.tag )}), tag contents: #{self.to_marc} "
          marc_node_log ["MISSING_MASTER", "TAG=#{self.tag}", "SUBTAG=#{@marc_configuration.get_master( self.tag )}", "MODEL=#{@model}", "ID-#{object_id}", "DEBUG=#{self.to_marc}"]
          #self.destroy_yourself
          return
        end
        
        unless master.foreign_object
          master.set_foreign_object
          master.foreign_host = true
          # also update the id - it might have changed or be missing (when submitted from the editor)
          master.content = master.foreign_object.id
        end
        # now add or update the dependant fields
        if dependants = @marc_configuration.get_foreign_dependants(self.tag, master.tag)
          dependants.each do |dep|
            dep_field = @marc_configuration.get_foreign_field(self.tag, dep)
            dep_tag = fetch_first_by_tag(dep)
            value = (master.foreign_object ? master.foreign_object.[](dep_field.intern) : nil)
            
            # For PSMD. If the foreign_fields contains a dot "."
            # It means we are following a relatio, eg
            # work.person.full_name. In this case call all the
            # methods to get the data. It is the same as in
            # looked_up_content.
            if master.foreign_object && dep_field.match(/\./)
              fields = dep_field.split('.')
              value = master.foreign_object.send(fields[0])
              (1..fields.count - 1).each {|n| value = value.send(fields[n]) }
            end
            
            if !dep_tag
              # the tag is missing in the source
              dep_tag = add(MarcNode.new(@model, dep, value, nil)) unless value.nil? or value.empty?
            else
              # update its value
              dep_tag.content = value unless value.nil? or value.empty?
            end
            # also set the foreign object for upcoming access to the field value
            dep_tag.set_foreign_object if dep_tag
            sort_alphabetically
          end
        end
      # this will happen with 004 in holding records
      elsif @marc_configuration.has_foreign_subfields(self.tag) && @marc_configuration.is_tagless?( self.tag )
        foreign_class = @marc_configuration.get_foreign_class(self.tag, "")
        self.foreign_object = foreign_class.constantize.send("find", self.content)
      end
    end
  end


  # Try to get a foreign object using the id. If the object does not exist,
  # create it. It is used during import of a Marc record, so relations (ex People or Library)
  # are established and in case created
  def find_or_new_foreign_object_by_foreign_field(class_name, field_name, search_value)
    new_foreign_object = nil
    if foreign_class = get_class(class_name)
      new_foreign_object = foreign_class.send("find_by_" + field_name, search_value)
      if !new_foreign_object

        # We need to make sure id is valid!
        if field_name == "id" && search_value.to_i == 0
          marc_node_log ["LINK_BY_MASTER", "FORMAT_INVALID", "MODEL=#{foreign_class}", "ID=#{search_value}"]
          # In nodmal operation muscat will try to create this item nevertheless
          # this is the option to change this behaviour
          return false if @force_marc_creation == false
        end

        new_foreign_object = foreign_class.new
        new_foreign_object.send("#{field_name}=", search_value)
        new_foreign_object.send("wf_stage=", 'published')
        marc_node_log ["LINK_BY_MASTER", "CREATE", "MODEL=#{foreign_class}", "ID=#{new_foreign_object.id}", "FIELD=#{field_name}", "VAL=#{search_value}"]
      else
        marc_node_log ["LINK_BY_MASTER", "MATCH", "MODEL=#{foreign_class}", "ID=#{new_foreign_object.id}", "FIELD=#{field_name}", "VAL=#{search_value}"]
      end
    end
    return new_foreign_object
  end

  # This works as find_or_new_foreign_object_by_foreign_field but instead of $0 id
  # it tries to use another field for the relation, as specified from the @marc_configuration.
  def find_or_new_foreign_object_by_all_foreign_fields(class_name, tag, nmasters)
    new_foreign_object = nil
    if foreign_class = get_class(class_name)
      conditions = Hash.new
      # put all the fields into a condition hash
      nmasters.each do |nmaster|
        conditions[@marc_configuration.get_foreign_field(tag, nmaster.tag)] = nmaster.looked_up_content if !nmaster.looked_up_content.empty?
      end
      # The imported fields are just... empty??
      # Note normally muscat will go on and do its thing,
      # returning here must be sxplicitly enabled
      return false if @force_marc_creation == false && conditions.empty?

      new_foreign_object = foreign_class.send("where", conditions).first
      if !new_foreign_object
        new_foreign_object = foreign_class.new
        new_foreign_object.send("wf_stage=", 'published')
        marc_node_log ["LINK_BY_ALL_FIELDS", "CREATE", "MODEL=#{foreign_class}", "ID=#{new_foreign_object.id}", "FIELDS=#{conditions}"]

      else
        marc_node_log ["LINK_BY_ALL_FIELDS", "MATCH", "MODEL=#{foreign_class}", "ID=#{new_foreign_object.id}", "FIELDS=#{conditions}"]
      end
    end
    return new_foreign_object
  end
  
  # Populate the master object, used during the import
  def populate_master( )
    if dependants = @marc_configuration.get_foreign_dependants( self.tag, @marc_configuration.get_master( self.tag ) )
      dependants.each do |dep|
        if dep_tag = fetch_first_by_tag(dep)
          dep_field = @marc_configuration.get_foreign_field( self.tag, dep)
          if self.foreign_object.new_record? or overwrite
            self.foreign_object.send("#{dep_field}=", dep_tag.content)
          else
            dep_tag.content = self.foreign_object.[](dep_field.intern)
          end
          # dep_tag.set_foreign_object
        end
      end
    end    
  end

  def populate_links_to(deftag)
    return if  !@marc_configuration.has_links_to(deftag)
    
    @marc_configuration.each_link_to(self.tag) do |subtag, model, field|
      tag = fetch_first_by_tag(subtag)
      next if !tag || !tag.content

      # Create the links_to, a stepped down version of the foreign links
      link_class = get_class(model)
      next if !link_class
      
      # Search the model for the value in the tag
      condition = Hash.new
      condition[field.to_sym] = tag.content
      link = link_class.where(condition).first

      # If it exists do nothing
      next if link
      
      # Does not exist, create a new one
      link = link_class.new
      link.send("wf_stage=", 'published')
      link.send("#{field}=", tag.content)

      # Link was not reindexed so it would not immediately show up in the list
      # This was done to save a bit of time when saving
      # link.suppress_reindex
      link.suppress_scaffold_marc if link.respond_to?(:suppress_scaffold_marc)
      begin
        link.save!
      rescue => e
        $stderr.puts
        $stderr.puts "Error saving link_to".red
        $stderr.puts e.message
        $stderr.puts "While importing: #{self.to_s}".yellow
      end
    end
  end
  
  def log_marc_value_changes(all_fields, tag, foreign_object)
    all_fields.each do |nm|
      next if !nm
      next if !nm.content
      ff = @marc_configuration&.get_foreign_field(tag, nm&.tag)
      next if !ff
      # Get the value in Muscat
      db_val = foreign_object.send(ff) rescue db_val = nil
      next if !db_val
      if db_val.downcase != nm.content.downcase
        marc_node_log [
          "IMPORT",
          "VALUE_CHANGE",
          "MODEL=#{foreign_object.class}",
          "ID=#{foreign_object.id}",
          "TAG=#{tag}",
          "SUBTAG=#{nm.tag}",
          "IMPORT_VAL=#{nm.content}",
          "DB_VAL=#{db_val.downcase}"
        ]
      end
    end
  end
  

  # Once the Marc data is parsed to MarcNodes, it can be
  # inspected to create the relations with the external classes
  # ex. People. This function does this. If the tag has a $0 with an id
  # (the field is returned by get_master_foreign_subfield) it will try
  # to get the corrensponding object from the DB. If no id ($0) is present
  # it will try to look it up
  def import(overwrite = false, reindex = false, user = nil)
    foreign_associations = {}
    if parent == nil
      @children.each do |child|
        child.suppress_scaffold_links if self.suppress_scaffold_links_trigger == true
        child_foreign_associations = child.import(overwrite, reindex, user)
        foreign_associations.merge!(child_foreign_associations) unless !child_foreign_associations
      end
    else
      self.sort_alphabetically
      
      # Before resolving the master fields, process the lightwheight link_to
      populate_links_to(self.tag)
      
      # Try to get the remote objects for this record
      if @marc_configuration.has_foreign_subfields(self.tag)
        self.foreign_object = nil
        master = get_master_foreign_subfield # master subfield (usually $0)
        nmasters = get_non_master_foreign_subfields # non master subfields ($a, etc.)
        # will be used to check if we already have a master ($0) or not
        add_master = false
        # will be used to check if we need to add a $_ db_master or not (for 004 we don't have one)
        add_db_master = true
        # If we have a master subfield, for the lookup using that
        if master
          master_field = @marc_configuration.get_foreign_field(tag, master.tag)
          self.foreign_object = find_or_new_foreign_object_by_foreign_field(@marc_configuration.get_foreign_class(tag, master.tag), master_field, master.looked_up_content)

          # In this case, it means found_obj was not created
          # because @force_marc_creation is false, try again
          if !self.foreign_object && @force_marc_creation == false
            # Try again, without using the master field
            master_tag = @marc_configuration.get_master( self.tag )
            self.foreign_object = find_or_new_foreign_object_by_all_foreign_fields( @marc_configuration.get_foreign_class(tag, master_tag), tag, nmasters )
          end

          # Use this to find ID collisions
          log_marc_value_changes(nmasters, tag, self.foreign_object) if defined?(:MARC_DEBUG) && $MARC_DEBUG

          # If we have no master subfiled but master is actually empty "" (e.g. 004) with holding records
        elsif !master && @marc_configuration.get_master( self.tag ) == ""
          add_db_master = false
          master_field = @marc_configuration.get_foreign_field(tag, "")
          self.foreign_object = find_or_new_foreign_object_by_foreign_field(@marc_configuration.get_foreign_class(tag, ""), master_field, self.content)
        # if not, there will be one or more non master fields, we can use to make a lookup and see if this 
        # object already exists
        elsif nmasters.size > 0
          # we will need to add a master (id), but only if the master if $0 (e.g., for 740, we don't add a $0 master)
          master_tag = @marc_configuration.get_master( self.tag )
          add_master = true
          self.foreign_object = find_or_new_foreign_object_by_all_foreign_fields( @marc_configuration.get_foreign_class(tag, master_tag), tag, nmasters )
        end
        return if !self.foreign_object
        
        # We have the foreign object. Check if it needs to be populated and saved
        if self.foreign_object.new_record? or overwrite
          self.foreign_object.user = user if user
          populate_master( )
          #FIXME self.foreign_object.suppress_reindex
          # PROBLEM: if an element has an incorrect id, but a field that is unique already is in the DB
          # the save will creash because of the duplicate field. In this case, we try an extreme remedy:
          # we try the lookup using non-masters so hopefully we can match the field to the one already there
          # and avoid the duplication crash
          self.foreign_object.suppress_reindex if reindex == false
          if self.suppress_scaffold_links_trigger == true
            self.foreign_object.suppress_scaffold_marc if self.foreign_object.respond_to?(:suppress_scaffold_marc)
          end
          begin
            # If this is a marc auth file suppress scaffolding
            # Removed for now, it seems it does not degrade performance too much
            #self.foreign_object.suppress_scaffold_marc if self.foreign_object.respond_to?(:suppress_scaffold_marc)

            unless self.foreign_object.save!
              puts "Foreign object could not be saved, possible duplicate?" # Try again not using master field lookup"
              # NOTE: THe code above is commented to allow duplicate entries in people/institutions for RISM A/I
              # see the Institutions model
              #master_tag = @marc_configuration.get_master( self.tag )
              #add_master = true if master_tag == "0"
              #self.foreign_object = find_or_new_foreign_object_by_all_foreign_fields( @marc_configuration.get_foreign_class(tag, master_tag), tag, nmasters )
              #puts "Foreign object could not be saved, no recovery from here." if !self.foreign_object.save
            end
          rescue => e
            $stderr.puts
            $stderr.puts "Marc Node Import error".red
            $stderr.puts e.message
            $stderr.puts "While importing: #{self.to_s}".yellow
            #$stderr.puts "Failed to save this foreign object: "
            #$stderr.puts  "#{self.foreign_object.to_yaml}"
            #$stderr.puts e.backtrace.join("\n")
          end
        end 
        # now add the master subfield $0 with the id value
        if add_master
          master_tag = @marc_configuration.get_master( self.tag )
          master = MarcNode.new(@model, master_tag, nil, nil )
          master.content = self.foreign_object.id
          add( master )
        end
        # populate the foreign associations hash
        foreign_associations[self.foreign_object.id] = self.foreign_object   
        # set the foreign object for all the subfields
        get_foreign_subfields.each do |subfield|
          subfield.set_foreign_object
        end
        # add the db_master subfield with the object id
        #if add_db_master
        #  db_master = MarcNode.new( "_", nil, nil )
        #  db_master.content = self.foreign_object.id
        #  add( db_master )
        #end
      end
    end
    return foreign_associations
  end

  # Check the zero padding for fields or subfields having this requirement (typically 14 charachter ids)
  def check_padding( tag, subtag )
    if (padding = @marc_configuration.get_zero_padding( tag, subtag )) && self.content != padding.to_i
      padding_string = "%0#{padding}d"
      self.content = padding_string % self.content.to_i
      puts "padding corrected for #{tag} (#{self.content})"
    end
    @children.each do |child|
      child.check_padding( tag, child.tag )
    end
  end
  
  # get the master subfield for a tag
  def get_master_foreign_subfield 
    masters = @children.reverse.select { |c| @marc_configuration.is_foreign?(self.tag, c.tag) and !@marc_configuration.get_foreign_class(self.tag, c.tag).match(/^\^/) }
    raise "only one master subfield is allowed: #{self.tag} #{masters.to_s}" if masters.size > 1
    return masters.size > 0 ? masters[0] : nil
  end
  
  # Get the all the tags that are not master for a subtag
  def get_non_master_foreign_subfields  
    @children.select { |c| @marc_configuration.is_foreign?(self.tag, c.tag) and !@marc_configuration.disable_create_lookup?(self.tag, c.tag) and @marc_configuration.get_foreign_class(self.tag, c.tag).match(/^\^/) }
  end
  
  # Get the all the tags that are foreign subfields (master and non master)
  def get_foreign_subfields  
    @children.select { |c| @marc_configuration.is_foreign?(self.tag, c.tag) }
  end
  
  # Get the foreign field and class for a foreign object
  def set_foreign_object
    foreign_class = @marc_configuration.get_foreign_class(self.parent.tag, self.tag)
    if parent.foreign_object == nil
      db_node = parent.fetch_first_by_tag(parent.get_master_foreign_subfield.tag)
      begin
        parent.foreign_object = foreign_class.constantize.send("find", db_node.content)
      rescue => e
        $stderr.puts "MarcNode set_foreign_object error".red
        $stderr.puts e.exception.to_s.blue
        $stderr.puts "MarcNode tag dump " + self.parent.to_marc.strip.yellow
        $stderr.puts "MarcNode offending or missing tag: " + self.to_marc.yellow
        raise e
      end
    end
    self.foreign_field = @marc_configuration.get_foreign_field(self.parent.tag, self.tag)
    self.foreign_object = parent.foreign_object
  end

  def get_relator_code
    subtag =  @marc_configuration.get_relator_code_tag(self.tag)
    if subtag
      val = fetch_first_by_tag(subtag)
      return val.content if val && val.content
    end
    return nil
  end

  # Return the content of this tag.
  def content
    if @foreign_object and @foreign_host
      return @foreign_object.id
    else
      return @content
    end
  end
  
  # Return the content of a foreign object non from the Marc data itself
  # but from the corresponding class
  def looked_up_content
    if @foreign_object and @foreign_field
      value = @foreign_object.[](@foreign_field.intern)
      
      # For PSMD. If the foreign_filed contains a dot "."
      # it means it is a relation that has to be resolved.
      # work.person.full_name. See resolve_externals above.
      if @foreign_field.match(/\./)
        fields = @foreign_field.split('.')
        value = @foreign_object.send(fields[0])
        (1..fields.count - 1).each {|n| value = value.send(fields[n])}
      end
      
      return value
    else
      return @content
    end
  end
  
  # Export to text Marc format
  def to_marc(no_db_id = false)
    out = String.new
    # skip the $_ tags (db_id)
    #return "" if tag == "_" and no_db_id
    value = looked_up_content # if looked_up_content
    if @tag =~ /^[\d\w]$/
      # subfield
      if value
        value = clean_string(value.to_s) #.gsub(/\$/, Marc::DOLLAR_STRING)
        out = "$#{@tag}#{value}"
      end
    else
      if @tag
        if @tag.to_i < 10
          #control tag
          out += "=#{@tag}  #{value}\r\n"
        else
          #data tag
          ind0 = " "
          ind1 = " "
          if indicator
            ind0 = indicator[0,1]
            ind1 = indicator[1,1]
          end
      		out += "=#{@tag}  #{ind0}#{ind1}"
          #for_every_child_sorted { |child| out += child.to_marc(no_db_id) }
      		@children.each { |child| out += child.to_marc(no_db_id) }
      		out += "\r\n"
        end
      else
        @children.each { |child| out += child.to_marc(no_db_id) }       
      end
    end

    return out
  end

  # Export to MarcXML - return a REXML::Element
  def to_xml_element(options = {})
    # deprecated ids are missing the model prefix and are ambiguous
    deprecated_ids = options.has_key?(:deprecated_ids) ? !(options[:deprecated_ids] == "false") : true
    element = XML::Node.new('leader')

    # skip the $_ (db_id)
    #return "" if tag == "_"
    out = String.new
    content = looked_up_content if looked_up_content
    if @tag =~ /^[\d]{3,3}$/
      if @tag.to_i == 0
        #control tag
        element.name = "leader"
        element << content.gsub(/#/," ")
      elsif @tag.to_i == 1
        element.name = "controlfield"
        # id tag - prefix approriately except if deprecated ids are requested
        element["tag"] = @tag
        element << ((deprecated_ids) ? content : "#{@model.to_s.pluralize.downcase}/#{content}")
      elsif @tag.to_i < 10
        #control tag
        element.name = "controlfield"
        # id tag - prefix approriately # problem: we are missing the _ when multiple words
        element["tag"] = @tag
        element << content
      else
        #data tag
        element.name = "datafield"
        element["tag"] = @tag
        ind0 = " "
        ind1 = " "
        if indicator
          ind0 = indicator[0,1]
          ind1 = indicator[1,1]
        end
        ind0 = " " if !ind0
        ind1 = " " if !ind1
        element["ind1"] = ind0.gsub(/[#\\]/," ")
        element["ind2"] = ind1.gsub(/[#\\]/," ")
        for_every_child_sorted { |child| element << child.to_xml_element(options) }
      end
    else
      #subfield
      element.name = "subfield"
      element["code"] = @tag
      cont_sanit = content.to_s
      # prefix ids appropriately except if deprecated ids are requested
      puts "Warning tag #{@parent.tag} is not in marc configuration".red if !@marc_configuration.has_tag?(@parent.tag)

      # By default, add just the id
      link = cont_sanit

      # Are we adding the model in the id?
      if !deprecated_ids
        # 774 is managed separately and need special treatment
        if @parent.tag == "774" && @tag == "w"
          code = @parent.fetch_first_by_tag("4")
          if code && code.content
            link = "#{code.content.pluralize}/#{cont_sanit}"
          else
            link = "sources/#{cont_sanit}"
          end
          
        # All the other ones are "automatic"
        elsif @marc_configuration.has_tag?(@parent.tag) && @tag == @marc_configuration.get_master(@parent.tag) && @foreign_object
          link = "#{@foreign_object.class.to_s.pluralize.underscore.downcase}/#{cont_sanit}"
        end
      end

      element << link

    end

    return element
  end
  
  # Export to JSON
  def to_json
    out = Array.new
    content = looked_up_content if looked_up_content
    if @tag =~ /^[\d]{3,3}$/
      if tag.to_i < 10
        #control
        out = {:type => 'controlfield', :tag => @tag, :content => content}
      else
        #data
        ind0 = " "
        ind1 = " "
        if indicator
          ind0 = indicator[0,1]
          ind1 = indicator[1,1]
        end
        thisfield = {:type =>'datafield', :tag => @tag, :ind0 => ind0, :ind1 => ind1, :subfields => []}
        for_every_child_sorted { |child| thisfield[:subfields] += [child.to_json] }
        out = thisfield
      end
    else
      # subfield
      out = {:type => 'subfield', :code => @tag, :content => content}
    end
    return out
  end
  
  # Set the foreign object
  def foreign_object=(object)
    @foreign_object = object
  end
  
  # Get the foreign object
  def foreign_object
    @foreign_object
  end
 
  # Set the foreign field
  def foreign_field=(field_name)
    @foreign_field = field_name
  end

  def get_class(classname)
    begin
      dyna_class = Kernel.const_get(classname)
    rescue 
      dyna_class = nil
    end
    dyna_class
  end
  
  # Set the parent object
  def parent=(parent)
    @parent = parent
  end
  
  # Return if this object has children
  def has_children?
    @children.length != 0
  end

  # Return the number of children
  def size
    @children.inject(1) {|sum, node| sum + node.size}
  end

  # Add a subfield
  def add(child)
    @children << child
    child.parent = self
    return child
  end

  # Return all children. can be used as block
  def children
    if block_given?
      @children.each { |child| yield child }
    else
      @children
    end
  end

  # Sort children and return them. can be used as block
  def for_every_child_sorted
    n = 0
    if block_given?
      @children.sort_by {|a| n += 1; [(a.tag.match(/\d/) ? "z#{a.tag}" : a.tag), n]}.each { |child| yield child }
      #@children.sort { |a, b| (a.tag.match(/\d/) ? "z#{a.tag}" : a.tag) <=> (b.tag.match(/\d/) ? "z#{b.tag}" : b.tag) }.each { |child| yield child }
    else
      #@children.sort { |a, b| (a.tag.match(/\d/) ? "z#{a.tag}" : a.tag) <=> (b.tag.match(/\d/) ? "z#{b.tag}" : b.tag) }
      @children.sort_by {|a| n += 1; [(a.tag.match(/\d/) ? "z#{a.tag}" : a.tag), n]}
    end
  end
  
  def all_children
    tags = Array.new
    for child in children
      tags << child
    end
    return tags
  end

  def each(&block)
    yield self if @parent
    children { |child| child.each(&block) }
  end
  
  def each_by_tag(tag)
    @children.each do |child|
      yield child if child.tag == tag.to_s
    end
  end
  
  def fetch_first_by_tag(tag)
    #s = @children.collect { |c| c.tag }.join(', ')
    @children.each do |child|
      return child if child.tag == tag.to_s
    end
    return nil
  end

  def fetch_all_by_tag(tag)
    matching_children = Array.new
    @children.each do |child|
      matching_children << child if child.tag == tag.to_s
    end
    return matching_children  
  end

  def destroy_yourself
    @parent.destroy_child(self) if @parent
  end
  
  def destroy_child(node)
    @children.delete_if { |child| child == node }
  end
  
  # Add an element at specified position
  def add_at(child, index)
    if child.model != @model && child.model
      puts "#{caller.first.red}: MarcNode add_at() child model #{child.model&.cyan} is not the same as root model #{@model&.cyan} [#{child.&to_s.strip}]"
    end
    @children.insert(index, child)
    child.parent = self
    return child
  end

  def sort_alphabetically
    n = 0
    @children = @children.sort_by {|a|
      n += 1
      [(a.tag.match(/\d/) ? "z#{a.tag}" : a.tag), n]
    }
  end

  def copy_to(destination_marc)
    new_tag = deep_copy
    destination_marc.root.children.insert(destination_marc.get_insert_position(new_tag.tag), new_tag)
  end

  # Are these two object identical also in the contents?
  def ===(other)
    return false if !other.is_a? MarcNode
    return false if tag != other.tag
    return false if children.count != other.children.count

    diff = other.children - children
    return false if !diff.empty?

    true
  end

  # eql? is used in difference() for arrays
  # so we can do a.children - b.children and see if they are all equal
  def eql?(other)
    if (!other.children || other.children.empty?) && (!children || children.empty?)
      return true if other.tag.to_s.strip == tag.to_s.strip && other.content.to_s.strip == content.to_s.strip
    end

    false
  end

  def <=>(other)
    return nil if !other.is_a? MarcNode
    # same object
    return 0 if self == other
    # same identical contents
    return 0 if self === other

    # if the tag is the same but not the contents, do a bare comparison
    return -1 if tag == other.tag && to_s.length <= other.to_s.length
    return 1 if tag == other.tag && to_s.length > other.to_s.length

    # different tags, order by tag
    return -1 if tag < other.tag
    return 1 if tag > other.tag
  end

  alias length size
  alias << add
  alias to_s to_marc
  alias inspect to_marc
  
  
  private
  def clean_string(str)
    single_space = " "
    return str.gsub(/[\r\n]+/, single_space).gsub(/\n+/, single_space).gsub(/\r+/, single_space).gsub(/\$/, Marc::DOLLAR_STRING)
  end
  
  def marc_node_log(list)
    return if !defined?(:MARC_DEBUG)
    return if !defined?(:MARC_LOG)
    return if !$MARC_DEBUG

    $MARC_LOG << ["MARC_NODE"] + list
  end

end
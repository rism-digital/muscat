require 'yaml'

# Loads the Marc Configuration. 
# Defines how various Tags are handled, shown or edited.
# Also specifies Configuration of Indicators and Subtags.
# The tag config is hardcoded in /config/marc/tag_config.5.0.yml

class MarcConfig

  # Creates a new Instance of a Marc Configuration
  # @see #load_config
  # @param tag_config_file_path [String] Path to Configuration (YAML) File
  # @return [MarcConfig]
  def initialize(tag_config_file_path)
    @model = load_config tag_config_file_path
  end

  private

  # Loads Marc Configuration from File
  # @param tag_config_file_path [String] Path to Configuration (YAML) File
  # @param overlay_path [String] Path to Overlay File
  # @return [MarcConfig]
  def load_config(tag_config_file_path, overlay_path = "")

    @whole_config = Settings.new( YAML::load(File.open(tag_config_file_path)) )

    config_file = File.basename(tag_config_file_path) # @todo The variable `config_file` seems to be unused
    overlay_file = overlay_path #File.join(Rails.root, 'config', 'marc', RISM::MARC, 'local_' + config_file)
    if File.exists?(overlay_file)
      @whole_config.squeeze(Settings.new(YAML::load(File.open(overlay_file))))
    end
    
    @tag_config = @whole_config[:tags]
    # @indexed_tags = Array.new
    @foreign_tags = Array.new
    @foreign_tag_groups = Array.new
    @foreign_dependants = Hash.new
    @has_browsable = Hash.new

    @tag_config.each do |tag, tdata|
      tagless = true
      @has_browsable[tag] = false
      tdata[:fields].each do |subtag, field_data|
        if subtag.to_s.length > 0
          tagless = false
        end

        @has_browsable[tag] = true unless field_data[:no_browse]

        if field_data[:foreign_class]
          @foreign_tag_groups.push(tag) unless @foreign_tag_groups.include? tag
          @foreign_tags.push(tag + subtag)
          if field_data[:foreign_class].match /\^([\w\d])/
            if @foreign_dependants[tag + $1]
              @foreign_dependants[tag + $1] << subtag
            else
              @foreign_dependants[tag + $1] = [subtag]
            end
          end
        end
      end
      @tag_config[tag][:tagless] = tagless
    end

    return @whole_config[:model]
  end

  public

  # Adds overlay to the Model
  # @param (see #load_config)
  def add_overlay(tag_config_file_path, overlay_path)
    @model = load_config tag_config_file_path, overlay_path
  end

  # Gets the model
  # @return [String] Name of the Model
  def get_model
    @model
  end

  # Returns all the configuration as YAML
  # @return [String] the whole Marc Configuration as YAML
  def to_yaml
    @whole_config.to_yaml
  end

  # Returns whether a tag is browsable, i.e. it will be shown to the user
  # @param tag [String] Tag Name
  # @return [Boolean]
  def tag_is_browsable?(tag)
    @has_browsable[tag]
  end

  # Gets the default indicator for a Marc tag
  # @param tag [String] Tag Name
  # @return [String] Marc Indicator
  def get_default_indicator(tag)
    return @tag_config[tag][:indicator][0] if @tag_config[tag][:indicator].is_a? Array
    @tag_config[tag][:indicator]
  end

  # Iterates over the Indicators for a Tag
  # @param tag [String] Tag Name
  def each_indicator(tag)
    if @tag_config[tag][:indicator].is_a? Array
      @tag_config[tag][:indicator].each { |ind| yield ind }
    else
      yield @tag_config[tag][:indicator]
    end
  end

  # Gets the Tags that refere to foreign Classes
  # @return [Array<String>] Tag Names
  def get_foreign_tag_groups
    @foreign_tag_groups
  end

  # Checks if a Tag and a Subtag should link to a foreign Class (i.e. People)
  # @param tag [String] Tag Name
  # @param subtag [String] Subtag Name
  # @return [Integer] Index of the Tag plus the Subtag or false
  # @todo Would be nicer to return 0 if no Tag and Subtag are found
  def is_foreign?(tag, subtag)
    if tag and subtag
      @foreign_tags.rindex(tag + subtag)
    else
      false
    end
  end

  # Gets the disable_create_lookup Flag
  # @param tag [String] Tag Name
  # @param subtag [String] Subtag Name
  # @return [Boolean]
  # @todo The return flag should be enough actually
  def disable_create_lookup?(tag, subtag)
    flag = @tag_config[tag][:fields].assoc(subtag)[1][:disable_create_lookup]
    return flag if flag
    false
  end

  # Gets the foreign class for a tag and subtag
  # @param tag [String] Tag Name
  # @param subtag [String] Subtag Name
  # @return [String] Foreign Class Name
  def get_foreign_class(tag, subtag)
    @tag_config[tag][:fields].assoc(subtag)[1][:foreign_class]
  end

  # Gets the foreign field that is connected to a foreign class
  # @param tag [String] Tag Name
  # @param subtag [String] Subtag Name
  # @return [String] Foreign Field Name
  def get_foreign_field(tag, subtag)
    @tag_config[tag][:fields].assoc(subtag)[1][:foreign_field]
  end

  # Gets the foreign alternative Field Names
  # @param tag [String] Tag Name
  # @param subtag [String] Subtag Name
  # @return [String] Foreign Alternatives
  def get_foreign_alternates(tag, subtag)
    @tag_config[tag][:fields].assoc(subtag)[1][:foreign_alternates]
  end

  # Gets the foreign Dependents
  # @param tag [String] Tag Name
  # @param subtag [String] Subtag Name
  # @return [String] Foreign Dependents
  # @todo Is this still used? What ist the return value?
  def get_foreign_dependants(tag, subtag)
    return @foreign_dependants[tag + subtag]
  end

  # Looks for the Number of foreign Subfields
  # @param tag [String] Tag Name
  # @return [Integer] Number of foreign Subfields or nil
  # @todo when and why is there going to be nil, when tag is empty?
  def has_foreign_subfields(tag)
    return @foreign_tag_groups.rindex(tag)
  end

  # Gets tags with references to a given Model
  # @param link_model [String] Model Name
  # @return [Array<String>] Tag Names
  def get_remote_tags_for(link_model)
    remote_tags = []
    get_foreign_tag_groups.each do |foreign_tag|
      each_subtag(foreign_tag) do |subtag|
        tag_letter = subtag[0]
        if is_foreign?(foreign_tag, tag_letter)
          # Note: in the configuration only ID has the Foreign class
          # The others use ^0
          next if get_foreign_class(foreign_tag, tag_letter) != link_model
          remote_tags << foreign_tag if !remote_tags.include? foreign_tag
        end
      end
    end
    remote_tags
  end

  # Gets all the References to foreign Models
  # @return [Array<String>] Model Names
  def get_all_foreign_classes()
    foreign_classes = []
    get_foreign_tag_groups.each do |foreign_tag|
      each_subtag(foreign_tag) do |subtag|
        tag_letter = subtag[0]
        if is_foreign?(foreign_tag, tag_letter)
          next if get_foreign_class(foreign_tag, tag_letter).include?("^")
          foreign_classes << get_foreign_class(foreign_tag, tag_letter).pluralize.underscore
        end
      end
    end
    foreign_classes
  end

  # Gets Links to Tag
  # @param tag [String] Tag Name
  # @return [Boolean] False
  # @todo does this ever not return false?
  def has_links_to(tag)
		return false if !@tag_config.include? tag
	  @tag_config[tag][:fields].each do |st|
		  return true if st[1].has_key?(:link_to_model) && st[1].has_key?(:link_to_field)
	  end
	  return false
  end
  
  # Interates over Links to Tags
  # @param tag [String] Tag Name
  def each_link_to(tag)
	  @tag_config[tag][:fields].each do |st|
		  yield(st[0], st[1][:link_to_model], st[1][:link_to_field]) if st[1].has_key?(:link_to_model) && st[1].has_key?(:link_to_field)
	  end
  end

  # Gets the foreign field 0 padding length for string field (if wanted)
  # @param tag [String] Tag Name
  # @param subtag [String] Subtag Name
  # @return [Nil]
  # @todo looks strange. Is it really a getter-Function? rescue nil is bad! Use try?
  def get_zero_padding(tag, subtag = "")
    # p tag
    # p subtag
    if subtag.empty?
        @tag_config[tag][:zero_padding] rescue nil
    else
      @tag_config[tag][:fields].assoc(subtag)[1][:zero_padding] rescue nil
    end
  end

  # Checks if a Tag or Subtag can be repeated (* or + mean it is)
  # disable_multiple means that duplication is disable IN EDITOR
  # but the field is allowed to be repeatable IN MARC
  # This is for Tag groups: a Field should not be repeatable in the Group
  # but can be repeated because of multiple Groups
  # @param tag [String] Tag Name
  # @param subtag [String] Subtag Name
  # @return [Boolean]
  def multiples_allowed?(tag, subtag = "")
    disable_multiple = false
    if subtag.empty?
        occurrences = @tag_config[tag][:occurrences]
        disable_multiple = @tag_config[tag][:disable_multiple] rescue disable_multiple = false
    else
        return false if !@tag_config[tag][:fields].assoc(subtag)
        occurrences = @tag_config[tag][:fields].assoc(subtag)[1][:occurrences]
        disable_multiple = @tag_config[tag][:fields].assoc(subtag)[1][:disable_multiple] rescue disable_multiple = false
    end
    return true if (occurrences == '*' or occurrences == '+') && !disable_multiple
    return false
  end

  # Gets a Tags Master-Subtag
  # @param tag [String] Tag Name
  # @return [String] Master-Subtag
  def get_master(tag)
    @tag_config[tag][:master]
  end


  # Gets the master_optional flag
  # @param tag [String] Tag Name
  # @todo Is this still used? Could not find any applications in the Models!
  def master_optional?(tag)
    @tag_config[tag][:master_optional]
  end

  # Tests for the Existence of Tag in the Marc Configuration
  # @param tag [String] Tag Name
  # @return [Boolean]
  def has_tag?(tag)
    return @tag_config.include?(tag)
  end

  # Tests for the Existence of Subtag in the Marc Configuration
  # @param tag [String] Tag Name
  # @param subtag [String] Subtag Name
  # @return [Boolean]
  def has_subfield?(tag, subtag )
    return true if @tag_config[tag][:fields].assoc(subtag)
    return false
  end

  # Tests Tags whether they are having Subtags
  # @param tag [String] Tag Name
  # @return [Boolean]
  def is_tagless?(tag)
    @tag_config[tag][:tagless]
  end

  # Tests whether a Tag is not browsable
  # @param tag [String] Tag Name
  # @param subtag [String] Subtag Name
  # @return [Boolean]
  # @todo replace rescue nil with try
  def show_in_browse?(tag, subtag)
    s = subtag.gsub(/\$/,"")
    !@tag_config[tag][:fields].assoc(s)[1][:no_browse] rescue nil
  end

  # Tests whether a Tag should be hidden
  # @param tag [String] Tag Name
  # @param subtag [String] Subtag Name
  # @return [Boolean]
  # @todo replace rescue nil with try
  def always_hide?(tag, subtag)
    s = subtag.gsub(/\$/,"")
    @tag_config[tag][:fields].assoc(s)[1][:no_show] rescue nil
  end

  # Tests whether Tag is inline
  # @param tag [String] Tag Name
  # @param subtag [String] Subtag Name
  # @return [Boolean]
  # @todo replace rescue nil with try
  def browse_inline?(tag, subtag)
    s = subtag.gsub(/\$/,"")
    @tag_config[tag][:fields].assoc(s)[1][:browse_inline] rescue nil
  end

  # Tests for Browse Helber
  # @param tag [String] Tag Name
  # @param subtag [String] Subtag Name
  # @return [Boolean]
  def get_browse_helper(tag, subtag)
    s = subtag.gsub(/\$/,"")
    @tag_config[tag][:fields].assoc(s)[1][:browse_helper]
  end


  # Gets the Size of the Tag
  # @param tag [String] Tag Name
  # @param subtag [String] Subtag Name
  # @return [Integer] Tag Size
  def get_size(tag, subtag)
    s = subtag.gsub(/\$/,"")
    @tag_config[tag][:fields].assoc(s)[1][:size] || 15
  end

  # Gets the Values of the Attributes of a Subtag
  # @param tag [String] Tag Name
  # @param subtag [String] Subtag Name
  # @param attribute_name [Symbol] Attribute
  # @return [String] Attribute Value
  def get_subtag_attribute(tag, subtag, attribute_name)
    pull = @tag_config[tag]
    if pull
      subpull = pull[:fields].assoc(subtag)
      if subpull
        return subpull[1][attribute_name]
      end
    end
    return nil
  end

  # Gets the Indicators
  # @param tag [String] Tag Name
  # @param subtag [String] Subtag Name
  # @return [String] Indicator
  #@todo: THIS IS ALL WRONG - indicator is now in top level - FIX!
  def get_indicator(tag, subtag = "")
    if @tag_config[tag][:fields].assoc(subtag)[1][:indicator].is_a? Array
      return @tag_config[tag][:fields].assoc(subtag)[1][:indicator][0]
    else
      return @tag_config[tag][:fields].assoc(subtag)[1][:indicator]
    end
  end

  # Returns iteraterable List of every Data-Tag
  # @return [Array] Data Tags
  def each_data_tag
    @tag_config.keys.sort.each { |tag| yield tag if tag.to_i > 8 }
  end

  # Returns iteraterable List of every Subtag of a Tag
  # @return [Array] Subtags
  def each_subtag( tag )
    @tag_config[tag][:fields].each { |subtag| yield subtag }
  end

  # Gets every Tag containing Subtag
  # @param subtag [String] Subtag Name
  # @return [Array<String>] Tags
  def tags_with_subtag( subtag )
    tags = Array.new
    @tag_config.keys.sort.each do |tag|
      tags << tag if @tag_config[tag][:fields].assoc(subtag)
    end
    tags
  end

  # Some magic functionality
  # @todo seems to be deprecated, no usecase found
  def dive(struct, from)
    struct.each do |k, v|
      if v.is_a?(Hash) and from[k]
        dive(v, from[k])
      else
        from[k] = v
      end
    end
  end

  # Some magic functionality
  # @todo seems to be deprecated, no usecase found
  def squeeze(other)
    other.each do |k, v|
      if v.is_a?(Hash) and @whole_config[k]
          dive(v, @whole_config[k])
        else
        update({ k => v })
      end
    end
  end
end

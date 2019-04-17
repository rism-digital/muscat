# encoding: UTF-8
# The editor configurations define how each marc_item will be printed/edited/shown. It builds uo the old EditorProfile
# and retains the full functionality.
# An editor configuration is comprised of a set of layout rules: i.e. which tags show and in which order. It enables to define labels in the same way.
# Layout options define how the editor fields will be constructed.
# Each EditorConfiguration can be applied only to a Source that has certain features, i.e. a regex match with the leader, the presence of a tag
# or the absence of a tag. Each of these rules is configured in the :filter field of the configuration file.
# The default configuration is in editor_profiles/defaul/profiles.yml; If an application wants to override it, it can define a new directory,
# e.g. editor_profiles/ch, and configure RISM::EDITOR_PROFILE="ch", for example. The new profiles completely overrides the default one.
# profiles.yml consists of an array of configurations, in this form:<p>
# <tt>
# - :id: Default
#  :name: Default 
#  :labels: 
#  - BasicLabels
#  :options: 
#  - BasicFormOptions
#  :layout: 
#  - LayoutDefaultCH
#  :filter: 
#    default: true
# </tt>
# <p>
# The options for :filter are:
# * <tt>default</tt> - set to true so this profile will be used as default, in case no other matches (for showing and editing)
# * <tt>show</tt> - set to true indicates that this is the default profile used for showing a ms
# * <tt>leader</tt> - Match the MARC Leader with a regexp: should be in the form <tt>leader: !ruby/regexp /.....npd.............../</tt>
# * <tt>tag</tt> - Will match only Sources that have this tag, ex. <tt>tag: "120"</tt>
# * <tt>no_tag</tt> - the reverse of the above, match Sources that do NOT have a tag
# * <tt>show_all</tt> - set to true to indicate that all tags, even the ones not configured, should be shown.
#
class EditorConfiguration
  
  # Load all the configurations, first in editor_profiles/default/configurations then ins
  # editor_profiles/# { RISM::EDITOR_PROFILE } /configurations. If two files share the same name
  # in the two directories, they will be merged together.
  def squeeze(list)
    configs = list #YAML::load(yaml_list)

    settings = Settings.new(Hash.new())
    
    if RISM::EDITOR_PROFILE != ""
      configs.each do |config|
        file = "#{Rails.root}/config/editor_profiles/#{RISM::EDITOR_PROFILE}/configurations/#{config}.yml"
        if File.exists?(file)
          settings.squeeze(Settings.new(IO.read(file)))
        end
      end
    else
      configs.each do |config|
        default_conf = "#{Rails.root}/config/editor_profiles/default/configurations/#{config}.yml"
        if File.exists?(default_conf)
          settings.squeeze(Settings.new(IO.read(default_conf)))
        end
      end
    end
    
    return settings
  end
    
  def initialize(conf)
    @name = conf[:name]
    @id = conf[:id]
    @filter = conf[:filter]
    @model = conf[:model]
    @squeezed_labels_config = squeeze(conf[:labels])
    @squeezed_options_config = squeeze(conf[:options])
    @squeezed_layout_config = squeeze(conf[:layout])
  end
  
  # Get the defined name from this EditorConfiguration, defined in :name
  def name
    @name
  end
  
  # Get the id for this EditorConfiguration, :id
  def id
    @id
  end
  
  # Get the :filter Hash for this EditorConfiguration
  def filter
    @filter
  end
  
  # Get the model for which this conf is applicable
  def model
    @model
  end
  
  #################################
  
  # Get the label configuration for the currently loaded profile.
  # they are defined, as a list, in :labels in profiles.yml
  def labels_config
    @squeezed_labels_config
  end
  
  # Get the sublabel. Generally used in Marc records for subrecords. For example, the YAML code
  # to set the name of $a for marc 028 (with localization):<p>
  # <tt>
  # Sublabel example
  # 028: !map:HashWithIndifferentAccess 
  #  label: !map:HashWithIndifferentAccess 
  #    it: Numero dell'editore
  #    fr: "Numéro d'éditeur"
  #    de: Verlagsnummer
  #    en: Publisher Number
  #  fields: !map:HashWithIndifferentAccess 
  #    a: !map:HashWithIndifferentAccess 
  #      label: !map:HashWithIndifferentAccess 
  #        it: Numero di lastra
  #        fr: "Numéro de plaque"
  #        de: Plattennummer
  #        en: Plate number
  # </tt>      
  def get_sub_label(id, sub_id, edit = false)
    # return :edit_label value only if edit and if existing
    if edit && labels_config[id] && labels_config[id][:fields] && labels_config[id][:fields][sub_id]&& labels_config[id][:fields][sub_id][:edit_label]
      return labels_config[id][:fields][sub_id][:edit_label][I18n.locale.to_s] if labels_config[id][:fields][sub_id][:edit_label][I18n.locale.to_s]
      return labels_config[id][:fields][sub_id][:edit_label][:en] if labels_config[id][:fields][sub_id][:edit_label][:en]
    end
    # else return :label
    if labels_config[id] && labels_config[id][:fields] && labels_config[id][:fields][sub_id] && labels_config[id][:fields][sub_id][:label] 
      return labels_config[id][:fields][sub_id][:label][I18n.locale.to_s] if labels_config[id][:fields][sub_id][:label][I18n.locale.to_s]
      return labels_config[id][:fields][sub_id][:label][:en] if labels_config[id][:fields][sub_id][:label][:en]
    end
    # if nothing found
    return "[unspecified]" 
  end
  
  # Returns if this label has a sublabel
  def has_sub_label?(id, sub_id)
    # we don't care about :edit_label here because we assume that we have an edit_label only if we also have :label
    if labels_config[id] && labels_config[id][:fields] && labels_config[id][:fields][sub_id] && labels_config[id][:fields][sub_id][:label]
      return true if labels_config[id][:fields][sub_id][:label][I18n.locale.to_s]
      return true if labels_config[id][:fields][sub_id][:label][:en]
    end
    return false
  end
 
  # Returns a comment if this label has one
  def get_comment(id, sub_id)
    if labels_config[id] && labels_config[id][:fields] && labels_config[id][:fields][sub_id] && labels_config[id][:fields][sub_id][:comment]
      return labels_config[id][:fields][sub_id][:comment]
    end
    return false
  end
  
  # Gets the localized label for the speficied field. Ex:<p>
  # <tt>
  # Label example
  # prt: !map:HashWithIndifferentAccess 
  #  label: !map:HashWithIndifferentAccess 
  #    it: Stampatore
  #    fr: Imprimeur
  #    de: Drucker
  #    en: Printer
  # </tt>
  def get_label(id, edit = false)
    # return :edit_label value only if edit and if existing
    if edit && labels_config[id] && labels_config[id][:edit_label]
      return labels_config[id][:edit_label][I18n.locale.to_s] if labels_config[id][:edit_label][I18n.locale.to_s]
      return labels_config[id][:edit_label][:en] if labels_config[id][:edit_label][:en]
    end
    # puts I18n.locale
    if labels_config[id] && labels_config[id][:label]
      return labels_config[id][:label][I18n.locale.to_s] if labels_config[id][:label][I18n.locale.to_s]
      return labels_config[id][:label][:en] if labels_config[id][:label][:en]
    end
    return "[unspecified]"
  end
  
  # Returns if the specified field has a label attached.
  def has_label?(id)
    if labels_config[id] && labels_config[id][:label]
      return true if labels_config[id][:label][I18n.locale.to_s]
      return true if labels_config[id][:label][:en]
    end
    return false
  end

  #################################

  # Gets the options for the current EditorConfiguration. As labels_config.
  # The form options are the options used in showing the edit fields in the ms editor
  def options_config
    unless @squeezed_options_config
      @squeezed_options_config = (cached_options ? cached_options : squeeze(struct_options))
    end
    @squeezed_options_config
  end
  
  # Extracts from the configuration the file name of the helpfile for the specified tag.
  # Help files oare in <tt>public/help</tt>. Used from the editor view.
  def get_tag_extended_help(tag_name, model)
    if options_config.include?(tag_name) && options_config[tag_name].include?("extended_help")
      return EditorConfiguration.get_help_fname("#{options_config[tag_name]["extended_help"]}", model)
    else
      return EditorConfiguration.get_help_fname("#{tag_name}", model)
    end
  end
  
  # gets the display partial for the specified tag from the configuration. Used so
  # the tag display can be customized from the configutarion.
  def get_tag_partial(partial, tag_name)
    if options_config.include?(tag_name) && options_config[tag_name].include?(partial)
      return "options/#{options_config[tag_name][partial]}"
    end
    return "editor/#{partial}"
  end
  
  # gets the display partial for the specified tag from the configuration. Used so
  # the tag display can be customized from the configutarion.
  # This call returns false if the partial is not found
  def get_tag_partial_no_default(partial, tag_name)
    if options_config.include?(tag_name) && options_config[tag_name].include?(partial)
      return "options/#{options_config[tag_name][partial]}"
    end
    return false
  end
  
  # gets the width of the specified tag in columns. It is used in the editor view so
  # The edit field for a tag can be more or less big.
  def get_column_for(tag_name, subfield_name)
    if options_config.include?(tag_name) and options_config[tag_name].include?("layout")
      f = options_config[tag_name]["layout"]["fields"].assoc(subfield_name)
      return f if f
    end
    return [subfield_name, {"cols" => 1}]
  end
  
  # Iterates on each subfield for the passed tag. Returns the field name and its config
  def each_subfield_for(tag_name)
    if options_config.include?(tag_name) && options_config[tag_name].include?("layout")
      # we must have 'fields' if we have 'layout'
      options_config[tag_name]["layout"]["fields"].each do |field, config|
        yield [field, config]
      end
    elsif labels_config.include?(tag_name) && labels_config[tag_name].include?(:fields)
      labels_config[tag_name][:fields].each do |field|
        yield [field[0], {"cols" => 1, "growfield" => true}]
      end
    end
  end
  
  
  # Iterates on the row element for each tag. Currently unused.
  def each_row_for(tag_name)
    if options_config.include?(tag_name) && options_config[tag_name].include?("layout")
      # we must have 'rows' if we have 'layout'
      options_config[tag_name]["layout"]["rows"].each do |row|
        #debugger
        yield row
      end
    elsif labels_config.include?(tag_name) && labels_config[tag_name].include?(:fields)
      # we just yield row of 100% for each subfield
      labels_config[tag_name][:fields].each do |field|
        yield [[field[0], {"width" => 100}]]
      end
    end
  end
  
  def get_triggers
    return options_config.include?("triggers") ? options_config["triggers"] : nil
  end

  #################################

  # Gets the layout for the current configuration. As labels_config.
  def layout_config
    @squeezed_layout_config
  end
  
  # build an array with all the tags in the layout_config
  # used by each_tag_not_in_layout 
  def layout_tags
    unless @layout_tags
      @layout_tags = Array.new
      layout_config["groups"].each do |group, gdata|
        gdata["all_tags"].each do |tag, tdata|
          @layout_tags.push tag
        end
      end
      @layout_tags.uniq!
      @layout_tags.sort!
    end
    @layout_tags 
  end
  
  # Returns an array of all the tags excluded for the record type (be they exluded in groups or by tag)
  def excluded_tags_for_record_type(marc_item)
    record_type =  (marc_item.respond_to? :record_type) ? marc_item.get_record_type : nil
    # no record_type for this model, or unknown, nothing exluced
    return [] if record_type == nil
    excluded = Array.new
    layout_config["groups"].each do |group, gdata|
      # Skip the group unless the group is excluded for the record type of the itme
      next unless
        record_type != nil && layout_config["group_exclude"] && 
        layout_config["group_exclude"][record_type.to_s] && 
        layout_config["group_exclude"][record_type.to_s].include?(group)
        gdata["all_tags"].each do |tag, tdata|
          excluded.push tag
        end
    end
    if layout_config["tag_exclude"] && layout_config["tag_exclude"][record_type.to_s]
      excluded.concat( layout_config["tag_exclude"][record_type.to_s] )
    end
    # also check if some tags are excluded if the item (source) has holdings
    if (marc_item.respond_to? :holdings) && (marc_item.holdings.size > 0)
      if layout_config["tag_exclude_with_holdings"] && layout_config["tag_exclude_with_holdings"][record_type.to_s]
		excluded.concat( layout_config["tag_exclude_with_holdings"][record_type.to_s] )
      end
    end
    excluded
  end
  
  # Returns an array with all the tags for the group but taking into account exclusiong by record type (if any)
  def layout_tag_names_for_group(marc_item, group)
    tag_names = Array.new
  	tag_names = layout_config["groups"][group]["all_tags"]
    record_type = (marc_item.respond_to? :record_type) ? marc_item.get_record_type : nil
	
	# Take in account tags excluded by holdings
	excluded_by_holdings = Array.new
    if (marc_item.respond_to? :holdings) && (marc_item.holdings.size > 0)
      if layout_config["tag_exclude_with_holdings"] && layout_config["tag_exclude_with_holdings"][record_type.to_s]
		excluded_by_holdings.concat( layout_config["tag_exclude_with_holdings"][record_type.to_s] )
      end
    end
	
	# Remove the tags
	tag_names -= excluded_by_holdings
	
    # no record_type for this model, or unknown, nothing exluced
    return tag_names if record_type == nil || !layout_config["tag_exclude"] || !layout_config["tag_exclude"][record_type.to_s]
    return tag_names - layout_config["tag_exclude"][record_type.to_s]
  end
    

  # build an array with all the tags in the layout_config that are not in a subfield grouping group
  # used by each_tag_not_in_layout 
  def layout_tags_not_in_subfield_grouping
    unless @layout_tags_not_in_subfield_grouping
      @layout_tags_not_in_subfield_grouping = Array.new
      layout_config["groups"].each do |group, gdata|
        next if gdata["subfield_grouping"]
        gdata["all_tags"].each do |tag, tdata|
          @layout_tags_not_in_subfield_grouping.push tag
        end
      end
      @layout_tags_not_in_subfield_grouping.uniq!
      @layout_tags_not_in_subfield_grouping.sort!
    end
    @layout_tags_not_in_subfield_grouping 
  end
  
  # Gets the default partial for the layout tag group
  def get_group_partial(group_name)
    if layout_config["groups"].include?(group_name) && layout_config["groups"][group_name].include?("editor_partial")
      return "layouts/#{layout_config["groups"][group_name]["editor_partial"]}"
    end
    return "editor/group"
  end  

  # Yields all the tags not included in the layout
  def each_group_in_layout(marc_item)
    record_type =  (marc_item.respond_to? :record_type) ? marc_item.get_record_type : nil
    layout_config["group_order"].each do |group|
      # Show the group unless the group is excluded for the record type of the itme
      yield group unless
        record_type != nil && layout_config["group_exclude"] && 
        layout_config["group_exclude"][record_type.to_s] && 
        layout_config["group_exclude"][record_type.to_s].include?(group)
    end
  end
  
  # Yields all the tags not included in the layout
  def each_tag_not_in_layout(marc_item)
    layout_tags
    # get the tags excluded for a particular record_type (if any)
    excluded = excluded_tags_for_record_type(marc_item)
    marc_item.marc.each_data_tags_present do |tag|
      yield tag if ((!layout_tags.include? tag) || (excluded.include? tag))
    end
  end
  
  # Returns if all the tags in the current layout should be shown. Used in the various tag partials.
  # show_all comes from the YAML <tt>filter</tt> in profiles.yml
  def show_all?
    return true if !@filter || !@filter.include?("show_all")
    return @filter["show_all"]
  end
  
  # Gets the default layout. This is a configuration in which <tt>default</tt> in the <tt>filter</tt> is true.
  def self.get_default_layout(model)
    profiles = EditorConfiguration.profiles
    model_name = model.class.to_s.downcase
    profiles.each do |p|
      next if model_name != p.model
      return p if p.filter && p.filter["default"]
    end
    return nil
  end
  
  # Gets the show layout. This is a configuration in which <tt>show</tt> in the <tt>filter</tt> is true.
  def self.get_show_layout(model)
    profiles = EditorConfiguration.profiles
    model_name = model.class.to_s.downcase
    profiles.each do |p|
      next if model_name != p.model
      return p if p.filter && p.filter["show"]
    end
    return nil
  end
    
  # Gets the html file name.
  def self.get_help_fname(name, model = "Source")
    model = (model == "Source") ? "" : "#{model.downcase}_"
    # translated version?
    fname = "/help/#{RISM::MARC}/#{model}#{name}_#{I18n.locale.to_s}.html"
    #ap fname
    return fname if File.exist?("#{Rails.root}/public#{fname}")
    # english?
    fname = "/help/#{RISM::MARC}/#{model}#{name}_en.html"
    return fname if File.exist?("#{Rails.root}/public#{fname}")
    # nope...
    return ""
  end

  private

  # Get all the EditorConfigurations defined in config/editor_profiles/default/profiles.yml
  # and locals is config/editor_profiles/$EDITOR_PROFILE/profiles.yml
  def self.profiles
    unless @squeezed_profiles
      # load global configurations
      @squeezed_profiles = Array.new
      
      # Load local configurations
      file = "#{Rails.root}/config/editor_profiles/#{RISM::EDITOR_PROFILE}/profiles.yml"
      if File.exists?(file)
        configurations = YAML::load(IO.read(file))
        configurations.each do |conf|
          @squeezed_profiles << EditorConfiguration.new(conf)
        end      
      else
        # if it does not exist, load default
        file = "#{Rails.root}/config/editor_profiles/default/profiles.yml"
        configurations = YAML::load(IO.read(file))
        configurations.each do |conf|
          @squeezed_profiles << EditorConfiguration.new(conf)
        end
      end
  
    end
    @squeezed_profiles
  end
    
  def self.get_profile_templates(model)
    templates = {}
    Dir.glob("#{Rails.root}/config/marc/#{RISM::MARC}/#{model}/*").sort.each do |f|
        file_dir = File.basename(f,'.marc')
        file_label = file_dir.sub(/[^_]*_/,"")
        templates[file_dir] = file_label
    end
    return templates
  end
  
  def self.get_source_templates
    file = "#{Rails.root}/config/marc/#{RISM::MARC}/source/template_configuration.yml"
    return {} if !File.exists?(file)
    
    conf = YAML::load(IO.read(file))
    return {} if !conf.has_key? "display"
    conf["display"]
  end
  
  def self.get_source_default_file(record_type)
    file = "#{Rails.root}/config/marc/#{RISM::MARC}/source/template_configuration.yml"
    return nil if !File.exists?(file)
    
    conf = YAML::load(IO.read(file))
    return nil if !conf.has_key? "default_mapping"
    conf["default_mapping"][record_type.to_s]
  end
  
end

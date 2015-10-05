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
# - :id: DefaultCH
#  :name: Default (CH)
#  :labels: 
#  - BasicLabels
#  :rules: 
#  - BasicCataloguingRules
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
  # editor_profiles/#{RISM::EDITOR_PROFILE}/configurations. If two files share the same name
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
    @squeezed_rules_config = squeeze(conf[:rules])
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
  
  # Gets the rules configuration from the DB. As labels_config above.
  def rules_config
    @squeezed_rules_config
  end

  #################################

  # Gets the options for the current EditorConfiguration. As labels_config and rules_config.
  # The form options are the options used in showing the edit fields in the ms editor
  def options_config
    unless @squeezed_options_config
      @squeezed_options_config = (cached_options ? cached_options : squeeze(struct_options))
    end
    @squeezed_options_config
  end
  
  # Extracts from the configuration the file name of the helpfile for the specified tag.
  # Help files oare in <tt>public/help</tt>. Used from the editor view.
  def get_tag_extended_help(tag_name)
    if options_config.include?(tag_name) && options_config[tag_name].include?("extended_help")
      return EditorConfiguration.get_help_fname("#{options_config[tag_name]["extended_help"]}")
    else
      return EditorConfiguration.get_help_fname("#{tag_name}")
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
  def each_subfield_for(tag_name, is_new = false)
    layout_key = is_new ? "layout_new" : "layout"
    if options_config.include?(tag_name) && options_config[tag_name].include?(layout_key)
      # we must have 'fields' if we have 'layout'
      options_config[tag_name][layout_key]["fields"].each do |field, config|
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

  #################################

  # Gets the layout for the current configuration. As labels_config and rules_config.
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
  
  # Returns all the tags not included in the layout
  def each_tag_not_in_layout(marc_item)
    layout_tags
    marc_item.marc.each_data_tags_present do |tag|
      yield tag if !layout_tags.include? tag
    end
  end
  
  # Returns if all the tags in the current layout should be shown. Used in the various tag partials.
  # show_all comes from the YAML <tt>filter</tt> in profiles.yml
  def show_all?
    return true if !@filter || !@filter.include?("show_all")
    return @filter["show_all"]
  end
  
  # Used from the SourceController, finds a layout that is applicabile for the current Source item
  # refer to _layout_is_applicable. It is filtered in base of the MARC leader or <tt>tag</tt> item.
  def self.get_applicable_layout(model)
    profiles = EditorConfiguration.profiles
    default = nil
    model_name = model.class.to_s.downcase

    profiles.each do |p|
      next if model_name != p.model
      
      # we keep the default profile while looping in case we don't find an applicable one
      default = p if p.filter && p.filter["default"]
      # we got it
      return p if self._layout_is_applicable model, p
    end
    return default
  end
  
  # Gets the default show layout. This is a configuration in which <tt>show</tt> in the <tt>filter</tt> is true.
  def self.get_show_layout(model)
    profiles = EditorConfiguration.profiles
    model_name = model.class.to_s.downcase
    profiles.each do |p|
      
      next if model_name != p.model
      
      return p if p.filter && p.filter["show"]
    end
    return nil
  end
  
  # Gets the default holding layout. This is a configuration in which <tt>holding</tt> in the <tt>filter</tt> is true.
  def self.get_holding_layout
    profiles = EditorConfiguration.profiles
    profiles.each do |p|
      return p if p.filter && p.filter["holding"]
    end
    return nil
  end
  
  # Gets the html file name.
  def self.get_help_fname(name)
    # translated version?
    fname = "/help/#{RISM::MARC}/#{name}_#{I18n.locale.to_s}.html"
    # puts fname
    return fname if File.exist?("#{Rails.root}/public#{fname}")
    # english?
    fname = "/help/#{RISM::MARC}/#{name}_en.html"
    return fname if File.exist?("#{Rails.root}/public#{fname}")
    # nope...
    return ""
  end

  private

  # Used by get_applicable_layout, checks passed marc_item and layout to see if the layout
  # is applicabile to the ms.
  def self._layout_is_applicable(marc_item, profile)
    return false if !profile.filter || !marc_item.marc
    # we don't want the default one, or show one
    return false if profile.filter["default"]
    return false if profile.filter["show"]
    # check if the leader matches the regexp
    if profile.filter["leader"]
      leader = marc_item.marc.get_leader
      r = Regexp.new(profile.filter["leader"])
      return false if !r.match(leader)
    end
    # check if the tag if present
    if profile.filter["tag"]
      return false if !marc_item.marc.has_tag?(profile.filter["tag"])
    end
    # check if the tag if NOT present
    if profile.filter["no_tag"]
      return false if marc_item.marc.has_tag?(profile.filter["no_tag"])
    end
    # it is applicable
    return true    
  end

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
  
  # Find the editor profile that matches the current passed if
  # kept so this class functions as a drop-in replacement for EditorProfile
  def self.find_by_id(elem)
    profiles.each do |profile|
      return profile if profile.id == elem
    end
    nil
  end
  
  def self.get_profile_templates(model)
    templates = {}
    # We just need to access the BasicLabels for the current RISM::MARC
    profile = EditorConfiguration.profiles[0]
		Dir.glob("#{Rails.root}/config/marc/#{RISM::MARC}/#{model}/*").sort.each do |f|
			if File.directory?(f)
				category = profile.get_label(File.basename(f,'.marc'))
        templates[category] = {}
				Dir.glob("#{f}/*.marc").sort.each do |ff|
					file_dir = File.basename(f) + "/" + File.basename(ff,'.marc')
          file_label = profile.get_label(File.basename(ff,'.marc'))
          templates[category][file_dir] = file_label
				end
			else
				file_dir = File.basename(f,'.marc')
        file_label = profile.get_label(File.basename(f,'.marc'))
        templates[file_dir] = file_label
			end
		end
    return templates
  end
  
end

# A Source is the base entity that is catalogued in RISM. 
# All the data is stored in the manuscripts
# table in a TEXT blob as MARC data. Fields that are important for brief display are
# mapped directly to fields in manuscripts and used exclusively for that purpose.  Any browsing or
# editting is performed on the marc record itself which is stored in the "source" field.  This field
# is aggregated to the {#Marc} class which understands the marc format.  All operations on the marc record 
# are handled by the {#Marc} class. 
# 
# @field <tt>id</tt> - numerical RISM id
# @field <tt>ms_lib_siglums</tt> - List of the library siglums, Library_id is nost stored anymore here, we use LibrariesSource for many-to-many 
# @field <tt>record_type</tt> - set to 1 id the ms. is anonymous, set to 2 if the ms. is a holding record
# @field <tt>std_title</tt> - Standard Title
# @field <tt>std_title_d</tt> - Standard title, downcase, with all UTF chars stripped (and substituted by ASCII chars)
# @field <tt>composer</tt> - Composer name
# @field <tt>composer_d</tt> - Composer, downcase, as standard title
# @field <tt>title</tt> - Title on manuscript (non standardized)
# @field <tt>title_d</tt> - Title on ms, downcase, chars stripped as in std_title_d and composer_d
# @field <tt>shelf_mark</tt> - source shelfmark
# @field <tt>language</tt> - Language of the text (if present) in the ms.
# @field <tt>date_from</tt> - First date on ms.
# @field <tt>date_to</tt> - Last date on ms.
# @field <tt>source</tt> - All the MARC data
# @field (standard wf_* fields are not shown)
#
# The Source class has also a belongs_to and has_many relationship to itself for linking parent <-> children sources,
# for example with collection and collection items or with bibligraphical and holding records for prints
# Database is UTF8 and collation utf8_general_ci which is NOT the strict UTF collation but rather one that
# is more suitable for english speakers.

class Source < ApplicationRecord
  # class variables for storing the user name and the event from the controller
  @last_user_save
  attr_accessor :last_user_save
  @last_event_save
  attr_accessor :last_event_save
  
  has_paper_trail :on => [:update, :destroy], :only => [:marc_source, :wf_stage], :if => Proc.new { |t| VersionChecker.save_version?(t) }
  
  # include the override for group_values
  require 'solr_search.rb'
#  include MarcIndex
  include ForeignLinks
  include MarcIndex
  include Template
  resourcify
  
  belongs_to :parent_source, {class_name: "Source", foreign_key: "source_id"}
  has_many :child_sources, {class_name: "Source"}
  has_many :digital_object_links, :as => :object_link, :dependent => :delete_all
  has_many :digital_objects, through: :digital_object_links, foreign_key: "object_link_id"
  has_and_belongs_to_many :institutions, join_table: "sources_to_institutions"
  has_and_belongs_to_many :people, join_table: "sources_to_people"
  has_and_belongs_to_many :standard_titles, join_table: "sources_to_standard_titles"
  has_and_belongs_to_many :standard_terms, join_table: "sources_to_standard_terms"
  has_and_belongs_to_many :catalogues, join_table: "sources_to_catalogues"
  has_and_belongs_to_many :liturgical_feasts, join_table: "sources_to_liturgical_feasts"
  has_and_belongs_to_many :places, join_table: "sources_to_places"
  has_many :holdings
	has_many :collection_holdings, {class_name: "Holding", foreign_key: "collection_id"}
  has_and_belongs_to_many :works, join_table: "sources_to_works"
  has_many :folder_items, as: :item, dependent: :destroy
  has_many :folders, through: :folder_items, foreign_key: "item_id"
  belongs_to :user, :foreign_key => "wf_owner"
  
  # This is the forward link
  has_and_belongs_to_many(:sources,
    :class_name => "Source",
    :foreign_key => "source_a_id",
    :association_foreign_key => "source_b_id",
    join_table: "sources_to_sources")
  
  # This is the backward link
  has_and_belongs_to_many(:referring_sources,
    :class_name => "Source",
    :foreign_key => "source_b_id",
    :association_foreign_key => "source_a_id",
    join_table: "sources_to_sources")
  
  composed_of :marc, :class_name => "MarcSource", :mapping => [%w(marc_source to_marc), %w(record_type record_type)]
  alias_attribute :id_for_fulltext, :id
  
  scope :in_folder, ->(folder_id) { joins(:folder_items).where("folder_items.folder_id = ?", folder_id) }
  
  # @todo FIXME id generation
  before_destroy :check_dependencies
  
  before_save :set_object_fields, :save_updated_at
  after_create :fix_ids
	after_initialize :after_initialize
  after_save :update_links, :reindex
  before_destroy :update_links_for_destroy

  attr_accessor :suppress_reindex_trigger
  attr_accessor :suppress_recreate_trigger
  attr_accessor :suppress_update_77x_trigger
  attr_accessor :suppress_update_count_trigger
  
  enum wf_stage: [ :inprogress, :published, :deleted, :deprecated ]
  enum wf_audit: [ :full, :abbreviated, :retro, :imported ]
  
  # Makes sure that newly initialized Instances are clean
  def after_initialize
    @old_parent = nil
    @last_user_save = nil
    @last_event_save = "update"
  end

  # Suppresses the recreation of the links with foreign MARC elements
  # (es libs, people, ...) on saving
  def suppress_recreate
    self.suppress_recreate_trigger = true
  end  
  
  # Suppresses the update of the 77x relations in MARC data
  # during the update
  def suppress_update_77x
    self.suppress_update_77x_trigger = true
  end
  
  # Suppresses the update of src_count
  # during the update
  def suppress_update_count
    self.suppress_update_count_trigger = true
  end
  
  def save_updated_at
    @old_updated_at = updated_at
  end

  # Syncs all the links from MARC data foreign relations
  # to the DB data cache. It will update on the DB
  # only those objects that are added or removed from
  # the foreign relation. This function does *not* update
  # the contents of the objects themselves, but it only
  # updates the relationship link tables on the DB.
  # It will update src_count if needed.
  # This trigger is disabled with {#suppress_recreate}.
  # src_count update is disabled with {#suppress_update_count}
  # It will also update the 77x relations in MARC data
  # unless {#suppress_update_77x} is set
  def update_links
    return if self.suppress_recreate_trigger == true
    
    allowed_relations = ["people", "standard_titles", "standard_terms", "institutions", "catalogues", "liturgical_feasts", "places", "holdings", "sources", "works"]
    recreate_links(marc, allowed_relations)
    
    # update the parent manuscript when having 773/774 relationships
    update_77x unless self.suppress_update_77x_trigger == true 
  end
  
  # A special case: if we are deleting the source
  # do not update the 77x links. This permits
  # us to delete sources that have invalid MARC data
  # since 77x forces a marc load
  def update_links_for_destroy
    suppress_update_77x
    update_links
  end

  # Suppresses the solr reindex
  def suppress_reindex
    self.suppress_reindex_trigger = true
  end
  
  # Reindex the Source Record
  # @return [RSolr::HashWithResponse]
  def reindex
    return if self.suppress_reindex_trigger == true
    self.index
  end

  # @todo What is this?
  searchable :auto_index => false do |sunspot_dsl| 
    sunspot_dsl.integer :id 
    sunspot_dsl.integer :record_type 
    sunspot_dsl.text :id_fulltext do |s|
      s.id_for_fulltext
    end 
    sunspot_dsl.text :source_id
    # For ordering
    sunspot_dsl.string :std_title_shelforder, :as => "std_title_shelforder_s" do |s|
      s.std_title
    end
    # For facet
    sunspot_dsl.string :std_title_order do |s|
      s.std_title
    end
    # For fulltext search
    sunspot_dsl.text :std_title, :stored => true
    sunspot_dsl.text :std_title_d
    sunspot_dsl.string :composer_order do |s|
      s.composer == "" ? nil : s.composer
    end
    sunspot_dsl.text :composer, stored: true do |s|
      "" if s.composer.blank?  
      begin
        tag = s.marc.first_occurance("100", "0")
      rescue ActiveRecord::RecordNotFound
        s.composer
      end
      if tag && tag.foreign_object && tag.foreign_object.alternate_names
        s.composer + "\n" + tag.foreign_object.alternate_names
      else
        s.composer
      end
    end
    sunspot_dsl.text :composer_d
    sunspot_dsl. string :title_order do |s|
      s.title
    end
    sunspot_dsl.text :title, :stored => true
    sunspot_dsl.text :title_d
    sunspot_dsl.string :shelf_mark_order do |s|
      s.shelf_mark
    end
	# This is a _very special_ case to have advanced indexing of shelfmarks
	# the solr dynamic field is "*_shelforder_s", so we can "trick" sunspot to load it
	# by calling the field :shelf_mark_shelforder -> sunspot translated it into shelf_mark_shelforder_s
	# when doing searches since the type is string.
	# This field type must be also configured in the schema.xml solr configuration
    sunspot_dsl.string :shelf_mark_shelforder, :stored => true, :as => "shelf_mark_shelforder_s" do |s|
			s.shelf_mark
		end
    sunspot_dsl.text :shelf_mark
    sunspot_dsl.string :lib_siglum_order do |s|
      s.lib_siglum
    end
    sunspot_dsl.text :lib_siglum, :stored => true, :as => "lib_siglum_s"
    # This one will be called lib_siglum_ss (note the second s) in solr
    # We use it for GIS
    sunspot_dsl.string :lib_siglum, :stored => true
    # Dates now come directly from MARC
#    sunspot_dsl.integer :date_from do 
#      date_from != nil && date_from > 0 ? date_from : nil
#    end
#    sunspot_dsl.integer :date_to do 
#      date_to != nil && date_to > 0 ? date_to : nil
#    end
    sunspot_dsl.integer :wf_owner, multiple: true do |s|
      s.holdings.map {|e| e.wf_owner} << s.wf_owner
    end
    sunspot_dsl.string :wf_stage
    sunspot_dsl.time :updated_at
    sunspot_dsl.time :created_at, multiple: true do |s|
      s.holdings.map {|e| e.created_at} << s.created_at
    end
    sunspot_dsl.join(:folder_id, :target => FolderItem, :type => :integer, 
              :join => { :from => :item_id, :to => :id })
    #For geolocation
    sunspot_dsl.latlon :location, :stored => true do |s|
      #lib = Institution.find_by_siglum(item[:value])
      #next if !lib
      lat = 0
      lon = 0
      begin
        lib = s.marc.first_occurance("852")
        if lib && lib.foreign_object
          lib_marc = lib.foreign_object.marc
          lib_marc.load_source false
          lat = lib_marc.first_occurance("034", "f")
          lon = lib_marc.first_occurance("034", "d")
          lat = (lat && lat.content) ? lat.content : 0
          lon = (lon && lon.content) ? lon.content : 0
        end
      rescue ActiveRecord::RecordNotFound
        puts "Could not load marc for coordinates"
      end
      Sunspot::Util::Coordinates.new(lat, lon)
    end
    sunspot_dsl.integer :copies, :stored => true do |s|
      if s.holdings.count > 0
        s.holdings.count
      else
        nil
      end
    end
    MarcIndex::attach_marc_index(sunspot_dsl, self.to_s.downcase)
  end
    
  # Checks for dependencies to other Records
  # @todo Exception :abort
  def check_dependencies
    if (self.child_sources.count > 0)
      errors.add :base, "The source could not be deleted because it has #{self.child_sources.count} child source(s)"
      throw :abort
    end
    if (self.digital_objects.count > 0)
      errors.add :base, "The source could not be deleted because it has digital objects attached"
      throw :abort
    end
    if (self.sources.count > 0)
      errors.add :base, "The source could not be deleted because it refers to #{self.sources.count} source(s)"
      throw :abort
    end
    if (self.referring_sources.count > 0)
      errors.add :base, "The source could not be deleted because it has #{self.referring_sources.count} subsequent entry(s)"
      throw :abort
    end
  end
    
  # Brings in the real data into the fields from marc structure
  # seeing as all other models are involved in x-many-x relationships and ids
  # are stored outside of the manuscripts table.
  # 
  # Fields are:
  # @field std_title
  # @field std_title_d
  # @field composer
  # @field composer_d
  # @field ms_title
  # @field ms_title_d
  # @field the _d variant fields store a normalized lower case version with accents removed
  # @field the _d columns are used for western dictionary sorting in list forms
  def set_object_fields
    return if marc_source == nil

    # source id
    ##marc_source_id = marc.get_marc_source_id
    ##self.id = marc_source_id if marc_source_id
    # @todo FIXME how do we generate ids?
    #self.marc.set_id self.id
    
    # parent source
    parent = marc.get_parent
    # If the 773 link is removed, clear the source_id
    # But before save it so we can update the parent
    # source.
    @old_parent = source_id if !parent
    self.source_id = parent ? parent.id : nil
        
    # std_title
    self.std_title, self.std_title_d = marc.get_std_title
    
    # composer
    self.composer, self.composer_d = marc.get_composer
    
    # @note we now decided to leave composer empty in all cases
    # when 100 is not set
    # Is composer set? if not this could be an anonymous
    #if self.composer == "" && self.record_type != MarcSource::RECORD_TYPES[:collection]
    #  self.composer, self.composer_d = ["Anonymous", "anonymous"]
    #end

    self.lib_siglum, self.shelf_mark = marc.get_siglum_and_shelf_mark
    
    # ms_title for bibliographic records
    self.title, self.title_d = marc.get_source_title
        
    # miscallaneous
    self.language, self.date_from, self.date_to = marc.get_miscellaneous_values

    self.marc_source = self.marc.to_marc
  end
  
  # If this manuscript is linked with another via 774/773, update if it is our parent
  def update_77x
    # do we have a parent manuscript?
    parent_manuscript_id = marc.first_occurance("773", "w")
    
    # @note we evaluate the strings prefixed by 00000
    # as the field may contain legacy values
    
    if parent_manuscript_id
      # We have a parent manuscript in the 773
      # Open it and add, if necessary, the 774 link
      parent_manuscript = Source.find_by_id(parent_manuscript_id.content)
      return if !parent_manuscript
      parent_manuscript.paper_trail_event = "Add 774 link #{id.to_s}"
      
      # check if the 774 tag already exists
      parent_manuscript.marc.each_data_tag_from_tag("774") do |tag|
        subfield = tag.fetch_first_by_tag("w")
        next if !subfield || !subfield.content
        return if subfield.content.to_i == id
      end
      
      # nothing found, add it in the parent manuscript
      mc = MarcConfigCache.get_configuration("source")
      w774 = MarcNode.new(@model, "774", "", mc.get_default_indicator("774"))
      w774.add_at(MarcNode.new(@model, "w", id.to_s, nil), 0 )
      parent_manuscript.marc.root.add_at(w774, parent_manuscript.marc.get_insert_position("774") )
      parent_manuscript.suppress_update_77x
      parent_manuscript.save
    else
      # We do NOT have a parent ms in the 773.
      # but we have it in old_parent, it means that
      # the 773 was deleted. Go into the parent and
      # find the reference to the id, then delete it
      if @old_parent
        parent_manuscript = Source.find_by_id(@old_parent)
        return if !parent_manuscript
        modified = false
        parent_manuscript.paper_trail_event = "Remove 774 link #{id.to_s}"
        
        # check if the 774 tag already exists
        parent_manuscript.marc.each_data_tag_from_tag("774") do |tag|
          subfield = tag.fetch_first_by_tag("w")
          next if !subfield || !subfield.content
          if subfield.content.to_i == id
            puts "Deleting 774 $w#{subfield.content} for #{@old_parent}, from #{id}"
            tag.destroy_yourself
            modified = true
          end
        end
        if modified
          parent_manuscript.suppress_update_77x
          parent_manuscript.save
          @old_parent = nil
        end
      end
    end
  end
  
  # Returns the Record Type
  # @return [Symbol]
  def get_record_type
    MarcSource::RECORD_TYPES.key(self.record_type)
  end
  
  # Checks whether the Record can be part of a #Holding
  # @return [Boolean]
  def allow_holding?
    if  (self.record_type == MarcSource::RECORD_TYPES[:edition] ||
         self.record_type == MarcSource::RECORD_TYPES[:libretto_edition] ||
         self.record_type == MarcSource::RECORD_TYPES[:theoretica_edition])
      return true
    end
    return false
  end
  
  # The ID should always be sync'ed if it was not generated by the DB
  # If it was scaffolded it is already here
  # If we imported a MARC record into Person, it is already here
  # This is basically only for when we have a new item from the editor
  def fix_ids
    #generate_new_id
    # If there is no marc, do not add the id
    return if marc_source == nil

    marc_source_id = marc.get_marc_source_id
    if !marc_source_id or marc_source_id == "__TEMP__"

      self.marc.set_id self.id
      self.marc_source = self.marc.to_marc
      # this is the new version
      PaperTrail.request(enabled: false) do
        save
      end
    end
  end
  
  # Returns the Standard Title of the Source
  # return [String] Standard Title
  def name  
    "#{composer} - #{std_title}"
  end
  
  # Returns the autocomplete label
  # return [String]
  def autocomplete_label
    "#{self.id}: #{self.composer} - #{self.std_title}"
  end
  
  # Converts Record to MarcXML
  # @return [String] MarcXML
  def to_marcxml
	  marc.to_xml(updated_at, versions)
  end
    
  # @return [String] Anonymous
  def marc_helper_set_anonymous
    "Anonymous"
  end

  # @todo What does it return?
  def last_updated_at
    @old_updated_at
  end

  # @todo What does it return?
  def get_collection_holding(holding_id)
    collection_holdings.each {|ch| return ch if ch.id == holding_id}
    nil
  end
  
  # @todo What does it return?
  def get_child_source(source_id)
    child_sources.each {|ch| return ch if ch.id == source_id}
    nil
  end

  # @todo What is this?
  ransacker :"852a_facet", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"593a_filter", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :record_type_select, proc{ |v| } do |parent| parent.table[:id] end
end

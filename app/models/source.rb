## A Source is the base entity that is catalogued in RISM. 
#
# All the data is stored in the manuscripts
# table in a TEXT blob as MARC data. Fields that are important for brief display are
# mapped directly to fields in manuscripts and used exclusively for that purpose.  Any browsing or
# editting is performed on the marc record itself which is stored in the "source" field.  This field
# is aggregated to the Marc class which understands the marc format.  All operations on the marc record 
# are handled by the Marc class.  See that class for more details.
# 
# === Fields
# * <tt>id</tt> - numerical RISM id
# * <tt>ms_lib_siglums</tt> - List of the library siglums, Library_id is nost stored anymore here, we use LibrariesSource for many-to-many 
# * <tt>record_type</tt> - set to 1 id the ms. is anonymous, set to 2 if the ms. is a holding record
# * <tt>std_title</tt> - Standard Title
# * <tt>std_title_d</tt> - Standard title, downcase, with all UTF chars stripped (and substituted by ASCII chars)
# * <tt>composer</tt> - Composer name
# * <tt>composer_d</tt> - Composer, downcase, as standard title
# * <tt>title</tt> - Title on manuscript (non standardized)
# * <tt>title_d</tt> - Title on ms, downcase, chars stripped as in std_title_d and composer_d
# * <tt>shelf_mark</tt> - source shelfmark
# * <tt>language</tt> - Language of the text (if present) in the ms.
# * <tt>date_from</tt> - First date on ms.
# * <tt>date_to</tt> - Last date on ms.
# * <tt>source</tt> - All the MARC data
# (standard wf_* fields are not shown)
#
# The Source class has also a belongs_to and has_many relationship to itself for linking parent <-> children sources,
# for example with collection and collection items or with bibligraphical and holding records for prints
#
# Database is UTF8 and collation utf8_general_ci which is NOT the strict UTF collation but rather one that
# is more suitable for english speakers.



class Source < ActiveRecord::Base
  
  # class variables for storing the user name and the event from the controller
  @last_user_save
  attr_accessor :last_user_save
  @last_event_save
  attr_accessor :last_event_save
  
  has_paper_trail :on => [:update, :destroy], :only => [:marc_source], :if => Proc.new { |t| VersionChecker.save_version?(t) }
  
  # include the override for group_values
  require 'solr_search.rb'
#  include MarcIndex
  include ForeignLinks
  include MarcIndex
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
  has_and_belongs_to_many :works, join_table: "sources_to_works"
  has_many :folder_items, :as => :item
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
  
  # FIXME id generation
  before_destroy :check_dependencies
  
  before_save :set_object_fields
  after_create :fix_ids
	after_initialize :after_initialize
  after_save :update_links, :reindex
  before_destroy :update_links_for_destroy
  
  attr_accessor :suppress_reindex_trigger
  attr_accessor :suppress_recreate_trigger
  attr_accessor :suppress_update_77x_trigger
  attr_accessor :suppress_update_count_trigger
  
  enum wf_stage: [ :inprogress, :published, :deleted ]
  enum wf_audit: [ :basic, :minimal, :full ]
  
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
  
  def suppress_update_77x
    self.suppress_update_77x_trigger = true
  end
  
  def suppress_update_count
    self.suppress_update_count_trigger = true
  end
  
  
  # Sync all the links from MARC data foreign relations
  # To the DB data cache. It will update on the DB
  # only those objects that are added or removed from
  # the foreign relation. This function does *not* update
  # the contents of the objects themselves, but it only
  # updates the relationship link tables on the DB.
  # It will update src_count if needed.
  # This trigger is disabled with suppress_recreate
  # src_count update is disabled with suppress_update_count
  # It will also update the 77x relations in MARC data
  # unless suppress_update_77x is set
  def update_links
    return if self.suppress_recreate_trigger == true
    
    allowed_relations = ["people", "standard_titles", "standard_terms", "institutions", "catalogues", "liturgical_feasts", "places", "holdings", "sources"]
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
  
  def reindex
    return if self.suppress_reindex_trigger == true
    self.index
  end

  

  searchable :auto_index => false do |sunspot_dsl|
   sunspot_dsl.integer :id
   sunspot_dsl.integer :record_type

    sunspot_dsl.text :id_fulltext do
      id_for_fulltext
    end
    
    sunspot_dsl.text :source_id
    
		# For ordering
    sunspot_dsl.string :std_title_shelforder, :as => "std_title_shelforder_s" do 
      std_title
    end
		# For facet
    sunspot_dsl.string :std_title_order do 
      std_title
    end
		# For fulltext search
    sunspot_dsl.text :std_title, :stored => true
    sunspot_dsl.text :std_title_d
    
    sunspot_dsl.string :composer_order do 
      composer == "" ? nil : composer
    end
    sunspot_dsl.text :composer, :stored => true
    sunspot_dsl.text :composer_d
        
    sunspot_dsl. string :title_order do 
      title
    end

    sunspot_dsl.text :title, :stored => true
    sunspot_dsl.text :title_d
    
    sunspot_dsl.string :shelf_mark_order do 
      shelf_mark
    end
	
	# This is a _very special_ case to have advanced indexing of shelfmarks
	# the solr dynamic field is "*_shelforder_s", so we can "trick" sunspot to load it
	# by calling the field :shelf_mark_shelforder -> sunspot translated it into shelf_mark_shelforder_s
	# when doing searches since the type is string.
	# This field type must be also configured in the schema.xml solr configuration
    sunspot_dsl.string :shelf_mark_shelforder, :stored => true, :as => "shelf_mark_shelforder_s" do
			shelf_mark
		end
    sunspot_dsl.text :shelf_mark
	
    sunspot_dsl.string :lib_siglum_order do
      lib_siglum
    end
    sunspot_dsl.text :lib_siglum, :stored => true, :as => "lib_siglum_s"
    
    sunspot_dsl.integer :date_from do 
      date_from != nil && date_from > 0 ? date_from : nil
    end
    sunspot_dsl.integer :date_to do 
      date_to != nil && date_to > 0 ? date_to : nil
    end
    
    sunspot_dsl.integer :wf_owner
    sunspot_dsl.string :wf_stage
	sunspot_dsl.time :updated_at
	sunspot_dsl.time :created_at

    sunspot_dsl.integer :catalogues, :multiple => true do
          catalogues.map { |catalogue| catalogue.id }
    end
    
    sunspot_dsl.integer :people, :multiple => true do
          people.map { |person| person.id }
    end
    
    sunspot_dsl.integer :places, :multiple => true do
          places.map { |place| place.id }
    end
    
    sunspot_dsl.integer :institutions, :multiple => true do
          institutions.map { |institution| institution.id }
    end
    
    sunspot_dsl.integer :liturgical_feasts, :multiple => true do
          liturgical_feasts.map { |lf| lf.id }
    end
    
    sunspot_dsl.integer :standard_terms, :multiple => true do
          standard_terms.map { |st| st.id }
    end
    
    sunspot_dsl.integer :standard_titles, :multiple => true do
          standard_titles.map { |stit| stit.id }
    end
    
    sunspot_dsl.join(:folder_id, :target => FolderItem, :type => :integer, 
              :join => { :from => :item_id, :to => :id })

    MarcIndex::attach_marc_index(sunspot_dsl, self.to_s.downcase)
  end
    
  def check_dependencies
    if (self.child_sources.count > 0)
      errors.add :base, "The source could not be deleted because it is used"
      return false
    end
    if (self.digital_objects.count > 0)
      errors.add :base, "The source could not be deleted because it is used"
      return false
    end
  end
    
  # Method: set_object_fields
  # Parameters: none
  # Return: none
  #
  # Brings in the real data into the fields from marc structure
  # seeing as all other models are involved in x-many-x relationships and ids
  # are stored outside of the manuscripts table.
  # 
  # Fields are:
  #  std_title
  #  std_title_d
  #  composer
  #  composer_d
  #  ms_title
  #  ms_title_d
  # 
  # the _d variant fields store a normalized lower case version with accents removed
  # the _d columns are used for western dictionary sorting in list forms
  def set_object_fields
    return if marc_source == nil

    # source id
    ##marc_source_id = marc.get_marc_source_id
    ##self.id = marc_source_id if marc_source_id
    # FIXME how do we generate ids?
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
    
    # NOTE we now decided to leave composer empty in all cases
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
    
    # NOTE we evaluate the strings prefixed by 00000
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
  
  def get_record_type
    MarcSource::RECORD_TYPES.key(self.record_type)
  end
  
  def allow_holding?
    return false if (self.record_type != MarcSource::RECORD_TYPES[:edition])
    return true
  end
  
  def fix_ids
    #generate_new_id
    # If there is no marc, do not add the id
    return if marc_source == nil

    # The ID should always be sync'ed if it was not generated by the DB
    # If it was scaffolded it is already here
    # If we imported a MARC record into Person, it is already here
    # THis is basically only for when we have a new item from the editor
    marc_source_id = marc.get_marc_source_id
    if !marc_source_id or marc_source_id == "__TEMP__"

      self.marc.set_id self.id
      self.marc_source = self.marc.to_marc
      self.without_versioning :save
    end
  end
  
  def self.find_recent_updated(limit, user)
    if user != -1
      where("updated_at > ?", 5.days.ago).where("wf_owner = ?", user).limit(limit).order("updated_at DESC")
    else
      where("updated_at > ?", 5.days.ago).limit(limit).order("updated_at DESC") 
    end
  end
  
  def name  
    "#{composer} - #{std_title}"
  end
  
  def autocomplete_label
    "#{self.id}: #{self.composer} - #{self.std_title}"
  end
  
  def to_marcxml
	  marc.to_xml(updated_at, versions)
  end
    
  def marc_helper_set_anonymous
    "Anonymous"
  end

  ransacker :"852a_facet_contains", proc{ |v| } do |parent| end
  ransacker :"593a_filter_with_integer", proc{ |v| } do |parent| end
	ransacker :record_type_select_with_integer, proc{ |v| } do |parent| end
	
end

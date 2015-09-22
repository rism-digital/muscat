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
  @@last_user_save
  cattr_accessor :last_user_save
  @@last_event_save
  cattr_accessor :last_event_save
  
  has_paper_trail :on => [:update, :destroy], :only => [:marc_source], :if => Proc.new { |t| VersionChecker.save_version?(t) }
  
  # include the override for group_values
  require 'solr_search.rb'
#  include MarcIndex
  resourcify
  
  belongs_to :source
  has_many :sources
  has_and_belongs_to_many :institutions
  has_and_belongs_to_many :people
  has_and_belongs_to_many :standard_titles
  has_and_belongs_to_many :standard_terms
  has_and_belongs_to_many :catalogues
  has_and_belongs_to_many :liturgical_feasts
  has_and_belongs_to_many :places
  has_and_belongs_to_many :works
  has_many :folder_items, :as => :item
  belongs_to :user, :foreign_key => "wf_owner"
  
  composed_of :marc, :class_name => "MarcSource", :mapping => %w(marc_source)
  alias_attribute :id_for_fulltext, :id
  
  # FIXME id generation
  before_destroy :check_dependencies
  
  before_save :set_object_fields
  after_create :fix_ids
  after_save :update_links, :reindex
  before_destroy :update_links
  
  # alias for holding records
  alias_attribute :ms_condition, :title  
  alias_attribute :image_urls, :title_d
  alias_attribute :urls, :composer_d
  # For bibliografic records in A/1, the old rism id goes into ms_no
  alias_attribute :book_id, :shelf_mark
  
  attr_accessor :suppress_reindex_trigger
  attr_accessor :suppress_recreate_trigger
  attr_accessor :suppress_update_77x_trigger
  attr_accessor :suppress_update_count_trigger
  
  def after_initialize
    @old_parent = nil
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
    
    marc_foreign_objects = Hash.new
    
    # All the allowed relation types *must* be in this array or they will be dropped
    allowed_relations = ["people", "standard_titles", "standard_terms", "institutions", "catalogues", "liturgical_feasts", "places"]
    
    # Group all the foreign associations by class, get_all_foreign_associations will just return
    # a flat list of objects
    marc.get_all_foreign_associations.each do |object_id, object|
      next if object.is_a? Source
      
      foreign_class = object.class.name.pluralize.underscore
      marc_foreign_objects[foreign_class] = [] if !marc_foreign_objects.include? (foreign_class)
      
      marc_foreign_objects[foreign_class] << object
      
    end
    
    # allowed_relations explicitly needs to contain the classes we will repond to
    # Log if in the Marc there are "unknown" classes, should never happen
    unknown_classes = marc_foreign_objects.keys - allowed_relations
    # If there are unknown classes purge them
    related_classes = marc_foreign_objects.keys - unknown_classes
    
    if !unknown_classes.empty?
      puts "Tried to relate with the following unknown classes: #{unknown_classes.join(',')}"
    end
    
    related_classes.each do |foreign_class|
      relation = self.send(foreign_class)
      
      # The foreign class array holds the correct number of object
      # We want to delete or add only the difference betweend
      # what is in marc and what is in the DB relations
      new_items = marc_foreign_objects[foreign_class] - relation.to_a
      remove_items = relation.to_a - marc_foreign_objects[foreign_class]
      
      # Delete or add to the DB relation
      relation.delete(remove_items)
      relation << new_items

      # If this item was manipulated, update also the src count
      # Unless the suppress_update_count is set
      if !self.suppress_update_count_trigger
        (new_items + remove_items).each do |o|
          o.update_attribute( :src_count, o.sources.count )
        end
      end
      
    end
    
    # update the parent manuscript when having 773/772 relationships
    update_77x unless self.suppress_update_77x_trigger == true 
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
    
    sunspot_dsl.string :std_title_order do 
      std_title
    end
    sunspot_dsl.text :std_title, :stored => true
    sunspot_dsl.text :std_title_d
    
    sunspot_dsl.string :composer_order do 
      composer == "" ? nil : composer
    end
    sunspot_dsl.text :composer, :stored => true
    sunspot_dsl.text :composer_d
    
    #sunspot_dsl.text :marc_source
    
    sunspot_dsl. string :title_order do 
      title
    end
    sunspot_dsl. text :title, :stored => true
    sunspot_dsl. text :title_d
    
    sunspot_dsl.string :shelf_mark_order do 
      shelf_mark
    end
    sunspot_dsl.text :shelf_mark, :stored => true
    
    sunspot_dsl.string :lib_siglum_order do
      lib_siglum
    end
    sunspot_dsl.text :lib_siglum, :stored =>true
    
    sunspot_dsl.integer :date_from do 
      date_from != nil && date_from > 0 ? date_from : nil
    end
    sunspot_dsl.integer :date_to do 
      date_to != nil && date_to > 0 ? date_to : nil
    end
    
    sunspot_dsl.integer :wf_owner
    sunspot_dsl.string :wf_stage
    
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
    
    sunspot_dsl.integer :works, :multiple => true do
          works.map { |work| work.id }
    end

    sunspot_dsl.join(:folder_id, :target => FolderItem, :type => :integer, 
              :join => { :from => :item_id, :to => :id })


    MarcIndex::attach_marc_index(sunspot_dsl, self.to_s.downcase)
  end
    
  def check_dependencies
    if (self.sources.count > 0)
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
    
    # record type
    self.record_type = 2 if marc.is_holding?
    
    # std_title
    self.std_title, self.std_title_d = marc.get_std_title
    
    # composer
    self.composer, self.composer_d = marc.get_composer
    
    # siglum and ms_no
    # in A/1 we do not have 852 in the bibliographic data
    # instead we store in ms_no the Book RISM ID (old rism id)
    if RISM::BASE == "a1" and record_type == 0
      self.book_id = marc.get_book_rism_id
    else
      self.lib_siglum, self.shelf_mark = marc.get_siglum_and_shelf_mark
    end
    
    # ms_title for bibliographic records
    self.title, self.title_d = marc.get_source_title if self.record_type != 2
    
    # physical_condition and urls for holding records
    self.ms_condition, self.urls, self.image_urls = marc.get_ms_condition_and_urls if self.record_type == 2
    
    # miscallaneous
    self.language, self.date_from, self.date_to = marc.get_miscellaneous_values

    self.marc_source = self.marc.to_marc
  end
  
  # If this manuscript is linked with another via 772/773, update if it is our parent
  def update_77x
    # do we have a parent manuscript?
    parent_manuscript_id = marc.first_occurance("773", "w")
    
    # NOTE we evaluate the strings prefixed by 00000
    # as the field may contain legacy values
    
    if parent_manuscript_id
      # We have a parent manuscript in the 773
      # Open it and add, if necessary, the 772 link
    
      parent_manuscript = Source.find_by_id(parent_manuscript_id.content)
      return if !parent_manuscript
      # check if the 772 tag already exists
      parent_manuscript.marc.each_data_tag_from_tag("772") do |tag|
        subfield = tag.fetch_first_by_tag("w")
        next if !subfield || !subfield.content
        
        return if subfield.content == id.to_s || subfield.content == "00000" + id.to_s
      end
      
      # nothing found, add it in the parent manuscript
      mc = MarcConfigCache.get_configuration("source")
      w772 = MarcNode.new(@model, "772", "", mc.get_default_indicator("772"))
      w772.add_at(MarcNode.new(@model, "w", id.to_s, nil), 0 )
      
      parent_manuscript.marc.root.add_at(w772, parent_manuscript.marc.get_insert_position("772") )

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
        
        # check if the 772 tag already exists
        parent_manuscript.marc.each_data_tag_from_tag("772") do |tag|
          subfield = tag.fetch_first_by_tag("w")
          next if !subfield || !subfield.content
          puts subfield.content
          if subfield.content == id.to_s || subfield.content == "00000" + id.to_s
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
    out = Array.new
    out << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    out << "<!-- Exported from RISM CH (http://www.rism-ch.org/) Dated: #{} -->\n"
    out << "<marc:collection xmlns:marc=\"http://www.loc.gov/MARC21/slim\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd\">\n"
    out << marc.export_xml
    out << "</marc:collection>" 
    return out.join('')
  end
    
end

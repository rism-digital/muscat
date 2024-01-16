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



class Source < ApplicationRecord

  # class variables for storing the user name and the event from the controller
  @last_user_save
  attr_accessor :last_user_save
  @last_event_save
  attr_accessor :last_event_save

  has_paper_trail :on => [:update, :destroy], :only => [:marc_source, :wf_stage], :if => Proc.new { |t| VersionChecker.save_version?(t) }

  # include the override for group_values
  require 'muscat/adapters/active_record/base.rb'
  include ForeignLinks
  include MarcIndex
  include Template
  include CommentsCleanup
  resourcify

  belongs_to :parent_source, class_name: "Source", foreign_key: "source_id"
  has_many :child_sources, class_name: "Source"
  has_many :digital_object_links, :as => :object_link, :dependent => :delete_all
  has_many :digital_objects, through: :digital_object_links, foreign_key: "object_link_id"

  #has_and_belongs_to_many :institutions, join_table: "sources_to_institutions"
  has_many :source_institution_relations
  has_many :institutions, through: :source_institution_relations

  #has_and_belongs_to_many :people, join_table: "sources_to_people"
  has_many :source_person_relations
  has_many :people, through: :source_person_relations

  #has_and_belongs_to_many :standard_titles, join_table: "sources_to_standard_titles"
  has_many :source_standard_title_relations
  has_many :standard_titles, through: :source_standard_title_relations

  #has_and_belongs_to_many :standard_terms, join_table: "sources_to_standard_terms"
  has_many :source_standard_term_relations
  has_many :standard_terms, through: :source_standard_term_relations


  has_and_belongs_to_many :publications, join_table: "sources_to_publications"
  has_and_belongs_to_many :liturgical_feasts, join_table: "sources_to_liturgical_feasts"
  has_and_belongs_to_many :places, join_table: "sources_to_places"
  has_many :holdings
	has_many :collection_holdings, class_name: "Holding", foreign_key: "collection_id"
  
  #has_and_belongs_to_many :works, join_table: "sources_to_works"
  has_many :source_work_relations
  has_many :works, through: :source_work_relations

  has_and_belongs_to_many :work_nodes, join_table: "sources_to_work_nodes"
  has_many :folder_items, as: :item, dependent: :destroy
  has_many :folders, through: :folder_items, foreign_key: "item_id"
  belongs_to :user, :foreign_key => "wf_owner"
  
  # source-to-source many-to-many relation
  # We need to switch to has_many to use an intermediate model
  # This is the forward relationship
  has_many :source_relations, foreign_key: "source_a_id"
  has_many :sources, through: :source_relations, source: :source_b
  # And this is the one coming back, i.e. sources pointing to this one from 775
  has_many :referring_source_relations, class_name: "SourceRelation", foreign_key: "source_b_id"
  has_many :referring_sources, through: :referring_source_relations, source: :source_a

  composed_of :marc, :class_name => "MarcSource", :mapping => [%w(marc_source to_marc), %w(record_type record_type)]
  alias_attribute :id_for_fulltext, :id

  scope :in_folder, ->(folder_id) { joins(:folder_items).where("folder_items.folder_id = ?", folder_id) }

  before_destroy :check_dependencies, :check_parent, prepend: true
  before_destroy :update_links_for_destroy, :cleanup_comments

  before_save :set_object_fields, :save_updated_at
  after_create :fix_ids
  after_initialize :after_initialize
  after_save :update_links, :reindex
  

  attr_accessor :suppress_reindex_trigger
  attr_accessor :suppress_recreate_trigger
  attr_accessor :suppress_update_77x_trigger
  attr_accessor :suppress_update_count_trigger

  enum wf_stage: [ :inprogress, :published, :deleted, :deprecated ]
  enum wf_audit: [ :full, :abbreviated, :retro, :imported ]

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

  def save_updated_at
    @old_updated_at = updated_at
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

    allowed_relations = ["people", "standard_titles", "standard_terms", "institutions", "publications", "liturgical_feasts", "places", "holdings", "sources", "work_nodes"]
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

    sunspot_dsl.integer :wf_owner

    sunspot_dsl.string :wf_stage
    sunspot_dsl.time :updated_at
    sunspot_dsl.time :created_at

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

    sunspot_dsl.text :text do |s|
      s.marc.to_raw_text
    end

    MarcIndex::attach_marc_index(sunspot_dsl, self.to_s.downcase)
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

    # parent source, can be nil
    parent = marc.get_parent ? marc.get_parent : nil
    # We need to save the parent (from 773) into source_id
    # before doing that, we make a backup to update_77x known
    # it has to modify the old parent. @old_parent wil be either
    # nil or different than the current parent, in that case
    # the record in @old_parent will have the 774 removed, if
    # it had one
    @old_parent = source_id
    # Update source_id on the DB only after we make a backup copy
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

  # Remove the 774 link from our parent if we are deleting
  # or changing the 773. Note that this function expects
  # @old_parent to contain the ID of the parent
  def delete_parent_774
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

  def add_parent_774(parent_manuscript_id)
      parent_manuscript = Source.find_by_id(parent_manuscript_id)
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
  end

  # If this manuscript is linked with another via 774/773, update if it is our parent
  def update_77x
    # do we have a parent manuscript?
    parent_manuscript_id = marc.first_occurance("773", "w")

    # NOTE we evaluate the strings prefixed by 00000
    # as the field may contain legacy values

    # We have a parent manuscript in the 773
    # Open it and add, if necessary, the 774 link
    if parent_manuscript_id && parent_manuscript_id.content
      parent_id = parent_manuscript_id.content.to_i
      # If we have @old_parent set, and it is different from the current
      # parent, it means the user switched 773, so we need to delete
      # the link in the old one.
      if @old_parent && @old_parent.to_i != parent_id
        delete_parent_774()
      end
      # Ok add the new link if necessary
      add_parent_774(parent_id)
    else
      # We do NOT have a parent ms in the 773.
      # but we have it in old_parent, it means that
      # the 773 was deleted. Go into the parent and
      # find the reference to the id, then delete it
      if @old_parent
        delete_parent_774()
      end

    end

  end

  def get_record_type
    MarcSource::RECORD_TYPES.key(self.record_type)
  end

  def allow_holding?
    if  (self.record_type == MarcSource::RECORD_TYPES[:edition] ||
         self.record_type == MarcSource::RECORD_TYPES[:libretto_edition] ||
         self.record_type == MarcSource::RECORD_TYPES[:theoretica_edition])
      return true
    end
    return false
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
      # this is the new version
      PaperTrail.request(enabled: false) do
        save
      end
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

  def last_updated_at
    @old_updated_at
  end

  def get_collection_holding(holding_id)
    collection_holdings.each {|ch| return ch if ch.id == holding_id}
    nil
  end

  def get_child_source(source_id)
    child_sources.each {|ch| return ch if ch.id == source_id}
    nil
  end

  def get_initial_entries
    self.sources.where("sources_to_sources.marc_tag": 775)
  end

  def siglum_matches?(siglum)
    if self.record_type == MarcSource::RECORD_TYPES[:edition] ||
      self.record_type == MarcSource::RECORD_TYPES[:libretto_edition] ||
      self.record_type == MarcSource::RECORD_TYPES[:theoretica_edition]
      holdings.each do |h|
        return true if h.lib_siglum.downcase.start_with? siglum.downcase
      end
    elsif self.record_type == MarcSource::RECORD_TYPES[:edition_content] ||
          self.record_type == MarcSource::RECORD_TYPES[:libretto_edition_content] ||
          self.record_type == MarcSource::RECORD_TYPES[:theoretica_edition_content]
      puts "Edition content #{self.id} has no parent" if !self.parent_source
      return false if !self.parent_source
      self.parent_source.holdings.each do |h|
        return true if h.lib_siglum.downcase.start_with? siglum.downcase
      end
    else
      return true if lib_siglum && lib_siglum.downcase.start_with?(siglum.downcase)
    end

    false
  end

  def get_shelfmarks
    if self.record_type == MarcSource::RECORD_TYPES[:edition] ||
      self.record_type == MarcSource::RECORD_TYPES[:libretto_edition] ||
      self.record_type == MarcSource::RECORD_TYPES[:theoretica_edition]
      return holdings.each.collect {|h| h.get_shelfmark}
    elsif self.record_type == MarcSource::RECORD_TYPES[:edition_content] ||
          self.record_type == MarcSource::RECORD_TYPES[:libretto_edition_content] ||
          self.record_type == MarcSource::RECORD_TYPES[:theoretica_edition_content]
      puts "Edition content #{self.id} has no parent" if !self.parent_source
      return [] if !self.parent_source
      return self.parent_source.holdings.each.collect {|h| h.get_shelfmark}
    end
    return [self.shelf_mark]
  end

  def manuscript_to_print(tags)
    is_child = self.parent_source != nil
    holding = Holding.new
    holding_marc = MarcHolding.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/holding/default.marc")))
    holding_marc.load_source false
    # Kill old 852s from the empty template
    holding_marc.each_by_tag("852") {|t2| t2.destroy_yourself}

    # First, insert a brand new 588 tag into the bib record

    a = self.marc.first_occurance("852", "a")
    c = self.marc.first_occurance("852", "c")
    elems = []
    elems << a.content if a and a.content
    elems << c.content if c and c.content

    content588 = elems.join(" ")

    if !is_child
      t588 = MarcNode.new("source", "588", "", '##')
      t588.add_at(MarcNode.new("source", "a", content588, nil), 0 )
      self.marc.root.add_at(t588, self.marc.get_insert_position("588") )
    end

    tags.each do |copy_tag, indexes|

      # Purge 593 only if we are copying over a new one
      holding_marc.each_by_tag("593") {|t2| t2.destroy_yourself} if copy_tag == "593"

      match = marc.by_tags(copy_tag)

      indexes.each do |i|
        match[i].copy_to(holding_marc)
        match[i].destroy_yourself
      end

    end

    # Save the holding
    if !is_child
      holding_marc.suppress_scaffold_links
      holding_marc.import
      
      holding.marc = holding_marc
      holding.source = self

      holding.save
    end
    
    # Do some housekeeping here too
    if !is_child
      self.record_type = MarcSource::RECORD_TYPES[:edition]
    else
      self.record_type = MarcSource::RECORD_TYPES[:edition_content]
    end
    self.save

    return holding.id
  end

  def get_iiif_tags()
    tags = self.marc.by_tags_with_order(["856"])

    if self.holdings
      self.holdings.each {|h| tags.concat(h.marc.by_tags_with_order(["856"]))}
    end

    tags.delete_if {|tag| subfield_x = tag.fetch_first_by_tag('x'); !subfield_x || !subfield_x.content || !subfield_x.content.include?("IIIF")}
    return tags
  end

  def force_marc_load?
    self.marc.load_source false
    true
  end

  def check_parent
    if source_id
      errors.add :base, I18n.t(:is_part_of_collection, class: self.class.model_name.human, id: self.id)
      throw :abort
      false
    end 
    true
  end

  ransacker :"852a_facet", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"852c", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"593a_filter", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"593b_filter", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"599a", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"856x", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :record_type_select, proc{ |v| } do |parent| parent.table[:id] end

end

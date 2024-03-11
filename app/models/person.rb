# A Person is a physical person tied to one or more Sources.
# a person reference is generally stored also in the source's marc data
#
# === Fields
# * <tt>full_name</tt> - Full name of the person: Second name, Name
# * <tt>full_name_d</tt> - Downcase with UTF chars stripped 
# * <tt>life_dates</tt> - Dates in the form xxxx-xxxx
# * <tt>birth_place</tt>
# * <tt>gender</tt> - 0 = male, 1 = female
# * <tt>composer</tt> - 1 =  it is a composer
# * <tt>source</tt> - Source from where the bio info comes from
# * <tt>alternate_names</tt> - Alternate spelling of the name
# * <tt>alternate_dates</tt> - Alternate birth/death dates if uncertain
# * <tt>src_count</tt> - Incremented every time a Source tied to this person
# * <tt>hls_id</tt> - Used to match this person with the its biografy at HLS (http://www.hls-dhs-dss.ch/)
#
# Other wf_* fields are not shown

class Person < ApplicationRecord
  include ForeignLinks
  include MarcIndex
  include AuthorityMerge
  include CommentsCleanup

  # class variables for storing the user name and the event from the controller
  @last_user_save
  attr_accessor :last_user_save
  @last_event_save
  attr_accessor :last_event_save
  
  has_paper_trail :on => [:update, :destroy], :only => [:marc_source], :if => Proc.new { |t| VersionChecker.save_version?(t) }
  
  def user_name
    user ? user.name : ''
  end
  
  resourcify 
  has_many :works
  has_many :digital_object_links, :as => :object_link, :dependent => :delete_all
  has_many :digital_objects, through: :digital_object_links, foreign_key: "object_link_id"

  #has_and_belongs_to_many(:referring_sources, class_name: "Source", join_table: "sources_to_people")
  has_many :source_person_relations, class_name: "SourcePersonRelation"
  has_many :referring_sources, through: :source_person_relations, source: :source

  #has_and_belongs_to_many(:referring_institutions, class_name: "Institution", join_table: "institutions_to_people")
  has_many :institution_person_relations, class_name: "InstitutionPersonRelation"
  has_many :referring_institutions, through: :institution_person_relations, source: :institution

  #has_and_belongs_to_many(:referring_holdings, class_name: "Holding", join_table: "holdings_to_people")
  has_many :holding_person_relations, class_name: "HoldingPersonRelation"
  has_many :referring_holdings, through: :holding_person_relations, source: :holding

  #has_and_belongs_to_many(:referring_publications, class_name: "Publication", join_table: "publications_to_people")
  has_many :publication_person_relations, class_name: "PublicationPersonRelation"
  has_many :referring_publications, through: :publication_person_relations, source: :publication

  #has_and_belongs_to_many(:referring_works, class_name: "Work", join_table: "works_to_people")
  has_many :work_person_relations, class_name: "WorkPersonRelation"
  has_many :referring_works, through: :work_person_relations, source: :work

  #has_and_belongs_to_many :institutions, join_table: "people_to_institutions"
  has_many :person_institution_relations
  has_many :institutions, through: :person_institution_relations

  #has_and_belongs_to_many :publications, join_table: "people_to_publications"
  has_many :person_publication_relations
  has_many :publications, through: :person_publication_relations

  #has_and_belongs_to_many :places, join_table: "people_to_places"
  has_many :person_place_relations
  has_many :places, through: :person_place_relations

  has_and_belongs_to_many(:referring_work_nodes, class_name: "WorkNode", join_table: "work_nodes_to_people")

  has_many :folder_items, as: :item, dependent: :destroy
  has_many :delayed_jobs, -> { where parent_type: "Person" }, class_name: 'Delayed::Backend::ActiveRecord::Job', foreign_key: "parent_id"
  belongs_to :user, :foreign_key => "wf_owner"
  
  # People can link to themselves
  # This is the forward link
#  has_and_belongs_to_many(:people,
#    :class_name => "Person",
#    :foreign_key => "person_a_id",
#    :association_foreign_key => "person_b_id",
#    join_table: "people_to_people")
  
  # This is the backward link
#  has_and_belongs_to_many(:referring_people,
#    :class_name => "Person",
#    :foreign_key => "person_b_id",
#    :association_foreign_key => "person_a_id",
#    join_table: "people_to_people")

  has_many :person_relations, foreign_key: "person_a_id"
  has_many :people, through: :person_relations, source: :person_b
  # And this is the one coming back
  has_many :referring_person_relations, class_name: "PersonRelation", foreign_key: "person_b_id"
  has_many :referring_people, through: :referring_person_relations, source: :person_a
  


  composed_of :marc, :class_name => "MarcPerson", :mapping => %w(marc_source to_marc)
  
#  validates_presence_of :full_name  
  validate :field_length
  
  #include NewIds
  
  before_destroy :check_dependencies, :cleanup_comments
  
  before_save :set_object_fields
  after_create :scaffold_marc, :fix_ids
  after_save :update_links, :reindex
  after_initialize :after_initialize
  
  attr_accessor :suppress_reindex_trigger
  attr_accessor :suppress_scaffold_marc_trigger
  attr_accessor :suppress_recreate_trigger

  alias_attribute :id_for_fulltext, :id

  enum wf_stage: [ :inprogress, :published, :deleted, :deprecated ]
  enum wf_audit: [ :full, :abbreviated, :retro, :imported ]

  def after_initialize
    @last_user_save = nil
    @last_event_save = "update"
  end

  # Suppresses the marc scaffolding
  def suppress_scaffold_marc
    self.suppress_scaffold_marc_trigger = true
  end
  
  def suppress_recreate
    self.suppress_recreate_trigger = true
  end 
  
  # This is the last callback to set the ID to 001 marc
  # A Person can be created in various ways:
  # 1) using new() without an id
  # 2) from new marc data ("New Person" in editor)
  # 3) using new(:id) with an existing id (When importing Sources and when created as remote fields)
  # 4) using existing marc data with an id (When importing MARC data into People)
  # Items 1 and 3 will scaffold new Marc data, this means that the Id will be copied into 001 field
  # For this to work, the scaffolding needs to be done in after_create so we already have an ID
  # Item 2 is like the above, but without scaffolding. In after_create we copy the DB id into 001
  # Item 4 does the reverse: it copies the 001 id INTO the db id, this is done in before_save
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
      PaperTrail.request(enabled: false) do
        save
      end
    end
  end
  
  def update_links
    return if self.suppress_recreate_trigger == true

    allowed_relations = ["institutions", "people", "places", "publications"]
    recreate_links(marc, allowed_relations)
  end
  
  # Do it in two steps
  # The second time it creates all the MARC necessary
  def scaffold_marc
    return if self.marc_source != nil  
    return if self.suppress_scaffold_marc_trigger == true
  
    new_marc = MarcPerson.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/person/default.marc")))
    new_marc.load_source true
    
    new_100 = MarcNode.new("person", "100", "", "1#")
    new_100.add_at(MarcNode.new("person", "a", self.full_name, nil), 0)
    
    if self.life_dates
      new_100.add_at(MarcNode.new("person", "d", self.life_dates, nil), 1)
    end
    
    pi = new_marc.get_insert_position("100")
    new_marc.root.children.insert(pi, new_100)

    if self.id != nil
      new_marc.set_id self.id
    end
    
    if self.birth_place && !self.birth_place.empty?
      new_field = MarcNode.new("person", "370", "", "##")
      new_field.add_at(MarcNode.new("person", "a", self.birth_place, nil), 0)
      
      new_marc.root.children.insert(new_marc.get_insert_position("370"), new_field)
    end
    
    if self.gender && self.gender == 1 # only if female...
      new_field = MarcNode.new("person", "375", "", "##")
      new_field.add_at(MarcNode.new("person", "a", "female", nil), 0)

      new_marc.root.children.insert(new_marc.get_insert_position("375"), new_field)
    end
    
    if (self.alternate_names != nil and !self.alternate_names.empty?) || (self.alternate_dates != nil and !self.alternate_dates.empty?)
      new_field = MarcNode.new("person", "400", "", "1#")
      name = (self.alternate_names != nil and !self.alternate_names.empty?) ? self.alternate_names : self.full_name
      new_field.add_at(MarcNode.new("person", "a", name, nil), 0)
      new_field.add_at(MarcNode.new("person", "d", self.alternate_dates, nil), 1) if (self.alternate_dates != nil and !self.alternate_dates.empty?)
      
      new_marc.root.children.insert(new_marc.get_insert_position("400"), new_field)
    end

    if self.source != nil and !self.source.empty?
      new_field = MarcNode.new("person", "670", "", "##")
      new_field.add_at(MarcNode.new("person", "a", self.source, nil), 0)
    
      new_marc.root.children.insert(new_marc.get_insert_position("670"), new_field)
    end

    self.marc_source = new_marc.to_marc
    self.save!
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
    sunspot_dsl.text :id_text do
      id_for_fulltext
    end
    sunspot_dsl.string :full_name_order do
      full_name
    end

    sunspot_dsl.string :full_name_ans, :as => "full_name_ans_s" do
      full_name
    end

    sunspot_dsl.text :full_name
    sunspot_dsl.text :full_name_d
    
    sunspot_dsl.string :life_dates_order do
      life_dates
    end
    sunspot_dsl.text :life_dates
    
    sunspot_dsl.text :birth_place
    sunspot_dsl.text :source
    sunspot_dsl.text :alternate_names
    sunspot_dsl.text :alternate_dates
    
    sunspot_dsl.integer :wf_owner
    sunspot_dsl.string :wf_stage
    sunspot_dsl.time :updated_at
    sunspot_dsl.time :created_at
    
    sunspot_dsl.text :text do |s|
      s.marc.to_raw_text
    end

    sunspot_dsl.join(:folder_id, :target => FolderItem, :type => :integer, 
              :join => { :from => :item_id, :to => :id })

    sunspot_dsl.integer :src_count_order, :stored => true do
      referring_sources.size + referring_holdings.size
    end
    
    MarcIndex::attach_marc_index(sunspot_dsl, self.to_s.downcase)
    
  end
    
  def set_object_fields
    # This is called always after we tried to add MARC
    # if it was suppressed we do not update it as it
    # will be nil
    return if marc_source == nil
    
    # If the source id is present in the MARC field, set it into the
    # db record
    # if the record is NEW this has to be done after the record is created
    marc_source_id = marc.get_marc_source_id
    # If 001 is empty or new (__TEMP__) let the DB generate an id for us
    # this is done in create(), and we can read it from after_create callback
    self.id = marc_source_id if marc_source_id and marc_source_id != "__TEMP__"

    # std_title
    self.full_name, self.full_name_d, self.life_dates = marc.get_full_name_and_dates
    
    # alternate
    self.alternate_names, self.alternate_dates = marc.get_alternate_names_and_dates
    
    # varia
    self.gender, self.birth_place, self.source = marc.get_gender_birth_place_and_source

    self.marc_source = self.marc.to_marc
  end
  
  def field_length
    self.life_dates = self.life_dates.truncate(24) if self.life_dates and self.life_dates.length > 24
    self.full_name = self.full_name.truncate(128) if self.full_name and self.full_name.length > 128
  end

  def name
    return full_name
  end
  
  def autocomplete_label
    "#{full_name}" + (life_dates && !life_dates.empty? ? "  - #{life_dates}" : "")
  end

  ransacker :"100d", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"375a", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"550a", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"100d_birthdate", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"100d_deathdate", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"043c", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"551a", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"667a", proc{ |v| } do |parent| parent.table[:id] end
	ransacker :"full_name_or_400a", proc{ |v| } do |parent| parent.table[:id] end

  def self.get_viaf(str)
    str.gsub!("\"", "")
    Viaf::Interface.search(str, self.to_s)
  end

  # rake sunspot:reindex calls indexable? to make sure this is an idexable record
  # We intercept this call to make a load_source false so it is faster to reindex
  # And we can harcdoce back the true since this model is solr indexable
  def indexable?
    self.marc.load_source false
    true
  end

end


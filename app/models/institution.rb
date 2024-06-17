# Describes a Library linked with a Source
#
# === Fields
# * <tt>siglum</tt> - RISM sigla of the lib
# * <tt>full_name</tt> -  Fullname of the lib
# * <tt>address</tt>
# * <tt>url</tt>
# * <tt>phone</tt> 
# * <tt>email</tt>
# * <tt>src_count</tt> - The number of manuscript that reference this lib.
#
# the other standard wf_* fields are not shown.
# The class provides the same functionality as similar models, see Publication

class Institution < ApplicationRecord
  include ForeignLinks
  include MarcIndex
  include AuthorityMerge
  include CommentsCleanup
  resourcify
  
  # class variables for storing the user name and the event from the controller
  @last_user_save
  attr_accessor :last_user_save
  @last_event_save
  attr_accessor :last_event_save
  
  has_paper_trail :on => [:update, :destroy], :only => [:marc_source], :if => Proc.new { |t| VersionChecker.save_version?(t) }
  
  has_many :digital_object_links, :as => :object_link, :dependent => :delete_all
  has_many :digital_objects, through: :digital_object_links, foreign_key: "object_link_id"

  #has_and_belongs_to_many(:referring_sources, class_name: "Source", join_table: "sources_to_institutions")
  has_many :source_institution_relations, class_name: "SourceInstitutionRelation"
  has_many :referring_sources, through: :source_institution_relations, source: :source
  
  #has_and_belongs_to_many :referring_holdings, class_name: "Holding", join_table: "holdings_to_institutions"
  has_many :holding_institution_relations, class_name: "HoldingInstitutionRelation"
  has_many :referring_holdings, through: :holding_institution_relations, source: :holding

  #has_and_belongs_to_many(:referring_people, class_name: "Person", join_table: "people_to_institutions")
  has_many :person_institution_relations, class_name: "PersonInstitutionRelation"
  has_many :referring_people, through: :person_institution_relations, source: :person

  #has_and_belongs_to_many(:referring_publications, class_name: "Publication", join_table: "publications_to_institutions")
  has_many :publication_institution_relations, class_name: "PublicationInstitutionRelation"
  has_many :referring_publications, through: :publication_institution_relations, source: :publication

  #has_and_belongs_to_many(:referring_works, class_name: "Work", join_table: "works_to_institutions")
  has_many :work_institution_relations, class_name: "WorkInstitutionRelation"
  has_many :referring_works, through: :work_institution_relations, source: :work

  #has_and_belongs_to_many :people, join_table: "institutions_to_people"
  has_many :institution_person_relations
  has_many :people, through: :institution_person_relations

  #has_and_belongs_to_many :publications, join_table: "institutions_to_publications"
  has_many :institution_publication_relations
  has_many :publications, through: :institution_publication_relations

  #has_and_belongs_to_many :places, join_table: "institutions_to_places"
  has_many :institution_place_relations
  has_many :places, through: :institution_place_relations

  has_many :folder_items, as: :item, dependent: :destroy
  has_many :delayed_jobs, -> { where parent_type: "Institution" }, class_name: 'Delayed::Backend::ActiveRecord::Job', foreign_key: "parent_id"
  has_and_belongs_to_many :workgroups
  belongs_to :user, :foreign_key => "wf_owner"
  
  has_and_belongs_to_many(:referring_work_nodes, class_name: "WorkNode", join_table: "work_nodes_to_institutions")


  #composed_of :marc, :class_name => "MarcInstitution", :mapping => %w(marc_source to_marc)

# OLD institutions_to_institutions
  # Institutions also can link to themselves
  # This is the forward link
#  has_and_belongs_to_many(:institutions,
#    :class_name => "Institution",
#    :foreign_key => "institution_a_id",
#    :association_foreign_key => "institution_b_id",
#    join_table: "institutions_to_institutions")
  
  # This is the backward link
#  has_and_belongs_to_many(:referring_institutions,
#    :class_name => "Institution",
#    :foreign_key => "institution_b_id",
#    :association_foreign_key => "institution_a_id",
#    join_table: "institutions_to_institutions")

# NEW institutions_to_institutions
  has_many :institution_relations, foreign_key: "institution_a_id"
  has_many :institutions, through: :institution_relations, source: :institution_b
  # And this is the one coming back
  has_many :referring_institution_relations, class_name: "InstitutionRelation", foreign_key: "institution_b_id"
  has_many :referring_institutions, through: :referring_institution_relations, source: :institution_a

  #validates_presence_of :siglum    
  
  validates_uniqueness_of :siglum, :allow_nil => true
  
  #include NewIds
  
  before_destroy :check_dependencies, :cleanup_comments
  
  #before_create :generate_new_id
  after_save :update_links, :reindex
  after_create :scaffold_marc, :fix_ids, :update_workgroups
  after_initialize :after_initialize
  
  before_validation :set_object_fields
  
  attr_accessor :suppress_reindex_trigger
  attr_accessor :suppress_scaffold_marc_trigger
  attr_accessor :suppress_recreate_trigger
  attr_accessor :suppress_update_workgroups_trigger

  alias_attribute :id_for_fulltext, :id
  alias_attribute :name, :full_name # activeadmin needs the name attribute

  enum wf_stage: [ :inprogress, :published, :deleted, :deprecated ]
  enum wf_audit: [ :full, :abbreviated, :retro, :imported ]
  
  def marc
    @marc ||= MarcInstitution.new(self.marc_source)
  end

  def marc=(marc)
    self.marc_source = marc.to_marc    
    @marc = marc
  end

  def after_initialize
    @last_user_save = nil
    @last_event_save = "update"
  end

  # Suppresses the solr reindex
  def suppress_reindex
    self.suppress_reindex_trigger = true
  end

  def suppress_scaffold_marc
    self.suppress_scaffold_marc_trigger = true
  end

  def suppress_recreate
    self.suppress_recreate_trigger = true
  end 

	def suppress_update_workgroups
		self.suppress_update_workgroups_trigger = true
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
      PaperTrail.request(enabled: false) do
        save
      end
    end
  end
  
  def update_links
    return if self.suppress_recreate_trigger == true

    allowed_relations = ["institutions", "people", "places", "publications", "standard_terms"]
    recreate_links(marc, allowed_relations)
  end

  def scaffold_marc
    return if self.marc_source != nil  
    return if self.suppress_scaffold_marc_trigger == true
  
    new_marc = MarcInstitution.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/institution/default.marc")))
    new_marc.load_source true
    
    new_110 = MarcNode.new("institution", "110", "", "1#")
    new_110.add_at(MarcNode.new("institution", "c", self.place, nil), 0) if self.place != nil
    new_110.add_at(MarcNode.new("institution", "g", self.siglum, nil), 0) if self.siglum != nil
    new_110.add_at(MarcNode.new("institution", "a", self.corporate_name, nil), 0)
    new_110.add_at(MarcNode.new("institution", "b", self.subordinate_unit, nil), 0) if self.subordinate_unit != nil
    
    new_marc.root.children.insert(new_marc.get_insert_position("110"), new_110)
    
    if self.alternates != nil and !self.alternates.empty?
      new_410 = MarcNode.new("institution", "410", "", "1#")
      new_410.add_at(MarcNode.new("institution", "a", self.alternates, nil), 0)
    
      new_marc.root.children.insert(new_marc.get_insert_position("410"), new_410)
    end
    
    if self.url || self.address
      new_371 = MarcNode.new("institution", "371", "", "1#")
      new_371.add_at(MarcNode.new("institution", "u", self.url, nil), 0) if self.url
      new_371.add_at(MarcNode.new("institution", "a", self.address, nil), 0) if self.address
    
      new_marc.root.children.insert(new_marc.get_insert_position("371"), new_371)
    end
    
    if self.notes != nil and !self.notes.empty?
      new_field = MarcNode.new("institution", "680", "", "1#")
      new_field.add_at(MarcNode.new("institution", "a", self.notes, nil), 0)
    
      new_marc.root.children.insert(new_marc.get_insert_position("680"), new_field)
    end
    
    

    if self.id != nil
      new_marc.set_id self.id
    end
    
    self.marc_source = new_marc.to_marc
    self.save!
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
    self.full_name, self.place = marc.get_full_name_and_place
    self.corporate_name, self.subordinate_unit = marc.get_corporate_name_and_subordinate_unit
    self.address, self.url = marc.get_address_and_url
    self.siglum = marc.get_siglum
    self.marc_source = self.marc.to_marc
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

    sunspot_dsl.string :siglum_order do
      siglum
    end
    sunspot_dsl.text :siglum
    
    sunspot_dsl.string :full_name_order do
      full_name
    end
    sunspot_dsl.text :full_name
    
    sunspot_dsl.string :place_order do
      place
    end
    sunspot_dsl.text :place
    
    sunspot_dsl.text :address
    sunspot_dsl.text :url
    sunspot_dsl.text :phone
    sunspot_dsl.text :email
    
    sunspot_dsl.join(:folder_id, :target => FolderItem, :type => :integer, 
              :join => { :from => :item_id, :to => :id })
    
    sunspot_dsl.integer :src_count_order, :stored => true do 
      referring_sources.size + referring_holdings.size
    end

    sunspot_dsl.integer :publications_count_order, :stored => true do
      referring_publications.size
    end

    sunspot_dsl.integer :wf_owner
    sunspot_dsl.string :wf_stage
    sunspot_dsl.time :updated_at
    sunspot_dsl.time :created_at

    sunspot_dsl.text :text do |s|
      s.marc.to_raw_text
    end

    MarcIndex::attach_marc_index(sunspot_dsl, self.to_s.downcase)
    
  end
  
  def update_workgroups
    return if self.suppress_update_workgroups_trigger == true || self.siglum.blank?
    Workgroup.all.each do |wg|
      patterns = wg.libpatterns.split(",")
      patterns.each do |pattern|
        wg.save if Regexp.new(pattern.strip).match(self.siglum)
      end
    end
  end
  
  def autocomplete_label
    sigla = siglum != nil && !siglum.empty? ? "#{siglum} " : ""
    "#{sigla}#{full_name}"
  end
  
  def autocomplete_label_siglum
    "#{siglum} (#{full_name})"
  end
  
  def autocomplete_label_name
    sigla = siglum != nil && !siglum.empty? ? " [#{siglum}]" : ""
    "#{full_name}#{sigla}"
  end
 
  ransacker :"110g_facet", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"667a", proc{ |v| } do |parent| parent.table[:id] end
   
  def holdings
    ActiveSupport::Deprecation.warn('Please use referring_holdings from institution')
    referring_holdings
  end
end

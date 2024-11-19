class Work < ApplicationRecord
  include ForeignLinks
  include MarcIndex
  include AuthorityMerge
  include CommentsCleanup
  include ComposedOfReimplementation

  # class variables for storing the user name and the event from the controller
  @last_user_save
  attr_accessor :last_user_save
  @last_event_save
  attr_accessor :last_event_save

  has_paper_trail :on => [:update, :destroy], :only => [:marc_source], :if => Proc.new { |t| VersionChecker.save_version?(t) }


  resourcify
  belongs_to :composer, class_name: "Person", foreign_key: "person_id"
  has_many :digital_object_links, :as => :object_link, :dependent => :delete_all
  has_many :digital_objects, through: :digital_object_links, foreign_key: "object_link_id"

  #has_and_belongs_to_many(:referring_sources, class_name: "Source", join_table: "sources_to_works")
  has_many :source_work_relations, class_name: "SourceWorkRelation"
  has_many :referring_sources, through: :source_work_relations, source: :source
  
  has_many :inventory_item_work_relations, class_name: "InventoryItemWorkRelation"
  has_many :referring_inventory_items, through: :inventory_item_work_relations, source: :inventory_item

  #has_and_belongs_to_many :publications, join_table: "works_to_publications"
  has_many :work_publication_relations
  has_many :publications, through: :work_publication_relations

  #has_and_belongs_to_many :standard_terms, join_table: "works_to_standard_terms"
  has_many :work_standard_term_relations
  has_many :standard_terms, through: :work_standard_term_relations

  #has_and_belongs_to_many :standard_titles, join_table: "works_to_standard_titles"
  has_many :work_standard_title_relations
  has_many :standard_titles, through: :work_standard_title_relations

  #has_and_belongs_to_many :liturgical_feasts, join_table: "works_to_liturgical_feasts"
  has_many :work_liturgical_feast_relations
  has_many :liturgical_feasts, through: :work_liturgical_feast_relations

  #has_and_belongs_to_many :institutions, join_table: "works_to_institutions"
  has_many :work_institution_relations
  has_many :institutions, through: :work_institution_relations

  #has_and_belongs_to_many :people, join_table: "works_to_people"
  has_many :work_person_relations
  has_many :people, through: :work_person_relations

  #has_and_belongs_to_many :places, join_table: "works_to_places"
  has_many :work_place_relations
  has_many :places, through: :work_place_relations

  has_many :folder_items, as: :item, dependent: :destroy
  has_many :delayed_jobs, -> { where parent_type: "Work" }, class_name: 'Delayed::Backend::ActiveRecord::Job', foreign_key: "parent_id"
  belongs_to :user, :foreign_key => "wf_owner"

#  has_and_belongs_to_many(:works,
#    :class_name => "Work",
#    :foreign_key => "work_a_id",
#    :association_foreign_key => "work_b_id",
#    join_table: "works_to_works")
  
#  # This is the backward link
#  has_and_belongs_to_many(:referring_works,
#    :class_name => "Work",
#    :foreign_key => "work_b_id",
#    :association_foreign_key => "work_a_id",
#    join_table: "works_to_works")

  has_many :work_relations, foreign_key: "work_a_id"
  has_many :works, through: :work_relations, source: :work_b
  has_many :referring_work_relations, class_name: "WorkRelation", foreign_key: "work_b_id"
  has_many :referring_works, through: :referring_work_relations, source: :work_a

  composed_of_reimplementation :marc, :class_name => "MarcWork", :mapping => %w(marc_source to_marc)

  before_destroy :check_dependencies, :cleanup_comments
  
  attr_accessor :suppress_reindex_trigger
  attr_accessor :suppress_scaffold_marc_trigger
  attr_accessor :suppress_recreate_trigger

  before_save :set_object_fields
  after_create :scaffold_marc, :fix_ids
  after_save :update_links, :reindex
  after_initialize :after_initialize

  enum wf_stage: [ :inprogress, :published, :deleted, :deprecated ]
  enum wf_audit: [ :normal, :obsolete, :doubtful, :fragment ]

  alias_attribute :name, :title
  alias_attribute :id_for_fulltext, :id

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

    allowed_relations = ["person", "publications", "standard_terms", "standard_titles", "liturgical_feasts", "institutions", "people", "works", "places"]
    recreate_links(marc, allowed_relations)
  end

  # Do it in two steps
  # The second time it creates all the MARC necessary
  def scaffold_marc
    return if self.marc_source != nil  
    return if self.suppress_scaffold_marc_trigger == true
  
    new_marc = MarcWork.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/work/default.marc")))
    new_marc.load_source true
    
    new_100 = MarcNode.new("work", "100", "", "1#")
    new_100.add_at(MarcNode.new("work", "t", self.title, nil), 0)
        
    pi = new_marc.get_insert_position("100")
    new_marc.root.children.insert(pi, new_100)

    if self.id != nil
      new_marc.set_id self.id
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
    sunspot_dsl.string :title_order do
      title
    end
    sunspot_dsl.text :title
    sunspot_dsl.text :opus
    sunspot_dsl.text :catalogue
    
    sunspot_dsl.integer :wf_owner
    sunspot_dsl.string :wf_stage
    sunspot_dsl.string :wf_audit
    sunspot_dsl.time :updated_at
    sunspot_dsl.time :created_at

    sunspot_dsl.string :opus_order, :stored => true, as: "opus_shelforder_s" do |s|
      s.opus if !s.opus.strip.empty?
    end
    sunspot_dsl.string :catalogue_order, :stored => true, as: "catalogue_shelforder_s" do |s|
      s.catalogue if !s.catalogue.strip.empty?
    end
    
    sunspot_dsl.string :catalogue_name_order, :multiple => true, :stored => true do |s|
      if !s.publications.empty?
        #1531, show only the ones in 690
        s.work_publication_relations.collect {|wpr| wpr.publication.name if wpr.marc_tag == "690"}
      else
        []
      end
    end

    sunspot_dsl.text :text do |s|
      s.marc.to_raw_text
    end

    sunspot_dsl.join(:folder_id, :target => FolderItem, :type => :integer, 
              :join => { :from => :item_id, :to => :id })

    sunspot_dsl.integer :src_count_order, :stored => true do 
      #self.marc.load_source false
      #self.marc.root.fetch_all_by_tag("856").size
      Work.count_by_sql("select count(*) from sources_to_works where work_id = #{self[:id]}")
    end
    
    sunspot_dsl.integer :publications_count_order, :stored => true do 
      Work.count_by_sql("select count(*) from works_to_publications where work_id = #{self[:id]}")
    end
    
    sunspot_dsl.boolean :has_music_incipit do |s|
      s.marc.has_incipits?
    end

    MarcIndex::attach_marc_index(sunspot_dsl, self.to_s.downcase)
  end
 

  def set_object_fields
    return if marc_source == nil
    self.title = marc.get_title
    # LP commented for work experiments. Person is set by hand in the script
    self.composer = marc.get_composer
    self.opus = marc.get_opus
    self.catalogue = marc.get_catalogue
    self.link_status = marc.get_link_status

    self.marc_source = self.marc.to_marc
  end
 
  def self.get_viaf(str)
    str.gsub!("\"", "")
    Viaf::Interface.search(str, self.to_s)
  end
 
  # If we define our own ransacker, we need this
  def self.ransackable_attributes(auth_object = nil)
    column_names + _ransackers.keys
  end

  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s }
  end

  ransacker :"031t", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"0242_filter", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :catalogue_name_order, proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"699a", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"690a", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"incipit", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"has_music_incipit", proc{ |v| } do |parent| parent.table[:id] end

end

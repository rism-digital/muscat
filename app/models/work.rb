class Work < ApplicationRecord
  include ForeignLinks
  include MarcIndex
  include AuthorityMerge

  # class variables for storing the user name and the event from the controller
  @last_user_save
  attr_accessor :last_user_save
  @last_event_save
  attr_accessor :last_event_save

  has_paper_trail :on => [:update, :destroy], :only => [:marc_source], :if => Proc.new { |t| VersionChecker.save_version?(t) }

  resourcify
  belongs_to :person
  has_many :digital_object_links, :as => :object_link, :dependent => :delete_all
  has_many :digital_objects, through: :digital_object_links, foreign_key: "object_link_id"
  has_and_belongs_to_many(:referring_sources, class_name: "Source", join_table: "sources_to_works")
  has_and_belongs_to_many :catalogues, join_table: "works_to_catalogues"
  has_and_belongs_to_many :standard_terms, join_table: "works_to_standard_terms"
  has_and_belongs_to_many :standard_titles, join_table: "works_to_standard_titles"
  has_and_belongs_to_many :liturgical_feasts, join_table: "works_to_liturgical_feasts"
  has_and_belongs_to_many :institutions, join_table: "works_to_institutions"
  has_and_belongs_to_many :people, join_table: "works_to_people"
  has_many :folder_items, as: :item, dependent: :destroy
  has_many :delayed_jobs, -> { where parent_type: "Work" }, class_name: 'Delayed::Backend::ActiveRecord::Job', foreign_key: "parent_id"
  belongs_to :user, :foreign_key => "wf_owner"
  has_and_belongs_to_many(:works,
    :class_name => "Work",
    :foreign_key => "work_a_id",
    :association_foreign_key => "work_b_id",
    join_table: "works_to_works")
  
  # This is the backward link
  has_and_belongs_to_many(:referring_works,
    :class_name => "Work",
    :foreign_key => "work_b_id",
    :association_foreign_key => "work_a_id",
    join_table: "works_to_works")
 
  composed_of :marc, :class_name => "MarcWork", :mapping => %w(marc_source to_marc)

  before_destroy :check_dependencies
  
  attr_accessor :suppress_reindex_trigger
  attr_accessor :suppress_scaffold_marc_trigger
  attr_accessor :suppress_recreate_trigger

  before_save :set_object_fields
  after_create :scaffold_marc, :fix_ids
  after_save :update_links, :reindex
  after_initialize :after_initialize

  enum wf_stage: [ :inprogress, :published, :deleted, :deprecated ]
  enum wf_audit: [ :basic, :minimal, :full ]

  alias_attribute :name, :title
  alias_attribute :id_for_fulltext, :id

  # @see #Source.after_initialize
  def after_initialize
    @last_user_save = nil
    @last_event_save = "update"
  end

  # Suppresses the marc scaffolding
  def suppress_scaffold_marc
    self.suppress_scaffold_marc_trigger = true
  end
  
  # Suppresses Recreation
  def suppress_recreate
    self.suppress_recreate_trigger = true
  end 

  # @see #Person.fix_ids
  def fix_ids
    #generate_new_id
    # If there is no marc, do not add the id
    return if marc_source == nil

    marc_source_id = marc.get_marc_source_id
    if !marc_source_id or marc_source_id == "__TEMP__"

      self.marc.set_id self.id
      self.marc_source = self.marc.to_marc
      PaperTrail.request(enabled: false) do
        save
      end
    end
  end
  
  # Updates the Relations to other Records 
  def update_links
    return if self.suppress_recreate_trigger == true

    allowed_relations = ["person", "catalogues", "standard_terms", "standard_titles", "liturgical_feasts", "institutions", "people", "works"]
    recreate_links(marc, allowed_relations)
  end

  # @see #Person.scaffold_marc
  def scaffold_marc
    return if self.marc_source != nil  
    return if self.suppress_scaffold_marc_trigger == true
    new_marc = MarcWork.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/work/default.marc"))
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
  
  # Reindexes the Record
  def reindex
    return if self.suppress_reindex_trigger == true
    self.index
  end

  # @todo What is this?
  searchable :auto_index => false do |sunspot_dsl|
    sunspot_dsl.integer :id
    sunspot_dsl.text :id_text do
      id_for_fulltext
    end
    sunspot_dsl.string :title_order do
      title
    end
    sunspot_dsl.text :title
    sunspot_dsl.text :title
    sunspot_dsl.integer :wf_owner
    sunspot_dsl.string :wf_stage
    sunspot_dsl.time :updated_at
    sunspot_dsl.time :created_at
    sunspot_dsl.join(:folder_id, :target => FolderItem, :type => :integer, 
              :join => { :from => :item_id, :to => :id })
    sunspot_dsl.integer :src_count_order, :stored => true do 
      Work.count_by_sql("select count(*) from sources_to_works where work_id = #{self[:id]}")
    end
    MarcIndex::attach_marc_index(sunspot_dsl, self.to_s.downcase)
  end

  # @see #Person.set_object_fields
  def set_object_fields
    return if marc_source == nil
    self.title = marc.get_title
    self.person = marc.get_composer
  end

  # @see #Person.check_dependencies
  def check_dependencies
    throw :abort if self.referring_sources.count > 0
  end
 
  # @see #Person.get_viaf
  def self.get_viaf(str)
    str.gsub!("\"", "")
    Viaf::Interface.search(str, self.to_s)
  end
 
  ransacker :"031t", proc{ |v| } do |parent| parent.table[:id] end

end

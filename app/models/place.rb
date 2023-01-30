# A Place describes a physical place - like a city - where a Source is found
#
# === Fields
# * <tt>name</tt>
# * <tt>country</tt>
# * <tt>district</tt>
# * <tt>notes</tt>
# * <tt>src_count</tt>
#
# Usual wf_* fields are not shown

class Place < ApplicationRecord
  include ForeignLinks

  has_and_belongs_to_many(:referring_sources, class_name: "Source", join_table: "sources_to_places")
  
  #has_and_belongs_to_many(:referring_people, class_name: "Person", join_table: "people_to_places")
  has_many :person_place_relations, class_name: "PersonPlaceRelation"
  has_many :referring_people, through: :person_place_relations, source: :person

  #has_and_belongs_to_many(:referring_institutions, class_name: "Institution", join_table: "institutions_to_places")
  has_many :institution_place_relations, class_name: "InstitutionPlaceRelation"
  has_many :referring_institutions, through: :institution_place_relations, source: :institution
  
  has_and_belongs_to_many(:referring_publications, class_name: "Publication", join_table: "publications_to_places")
  has_and_belongs_to_many(:referring_holdings, class_name: "Holding", join_table: "holdings_to_places")
  has_many :folder_items, as: :item, dependent: :destroy
  has_many :delayed_jobs, -> { where parent_type: "Place" }, class_name: 'Delayed::Backend::ActiveRecord::Job', foreign_key: "parent_id"
  belongs_to :user, :foreign_key => "wf_owner"

  validates_presence_of :name

  validates_uniqueness_of :name

  #include NewIds

  before_destroy :check_dependencies

  #before_create :generate_new_id
  after_save :reindex

  attr_accessor :suppress_reindex_trigger

  alias_attribute :id_for_fulltext, :id

  enum wf_stage: [ :inprogress, :published, :deleted, :deprecated ]
  enum wf_audit: [ :basic, :minimal, :full ]

  # Suppresses the solr reindex
  def suppress_reindex
    self.suppress_reindex_trigger = true
  end

  def reindex
    return if self.suppress_reindex_trigger == true
    self.index
  end

  searchable :auto_index => false do
    integer :id
    text :id_text do
      id_for_fulltext
    end
    string :name_order do
      name
    end
    text :name

    string :country_order do
      country
    end
    text :country

    text :notes
    text :alternate_terms
    text :topic
    text :sub_topic
    text :district

    join(:folder_id, :target => FolderItem, :type => :integer, 
              :join => { :from => :item_id, :to => :id })
    
    integer :src_count_order, :stored => true do 
      Place.count_by_sql("select count(*) from sources_to_places where place_id = #{self[:id]}")
    end

    integer :person_count_order, :stored => true do 
      Place.count_by_sql("select count(*) from people_to_places where place_id = #{self[:id]}")
    end

    integer :institution_count_order, :stored => true do 
      Place.count_by_sql("select count(*) from institutions_to_places where place_id = #{self[:id]}")
    end

    integer :publication_count_order, :stored => true do 
      Place.count_by_sql("select count(*) from publications_to_places where place_id = #{self[:id]}")
    end

    integer :holding_count_order, :stored => true do 
      Place.count_by_sql("select count(*) from holdings_to_places where place_id = #{self[:id]}")
    end

  end

end


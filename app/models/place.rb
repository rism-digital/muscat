# A Place describes a physical place - like a city - where a Source is found
#
# @field <tt>name</tt>
# @field <tt>country</tt>
# @field <tt>district</tt>
# @field <tt>notes</tt>
# @field <tt>src_count</tt>
# @field Usual wf_* fields are not shown

class Place < ApplicationRecord
  has_and_belongs_to_many(:referring_sources, class_name: "Source", join_table: "sources_to_places")
  has_and_belongs_to_many(:referring_people, class_name: "Person", join_table: "people_to_places")
  has_and_belongs_to_many(:referring_institutions, class_name: "Institution", join_table: "institutions_to_places")
  has_and_belongs_to_many(:referring_catalogues, class_name: "Catalogue", join_table: "catalogues_to_places")
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

  # Reindexes the Record
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
  end

  # Checks for Relations to other Records
  def check_dependencies
    if self.referring_sources.count > 0 || self.referring_institutions.count > 0 ||
         self.referring_catalogues.count > 0 || self.referring_people.count > 0 || self.referring_holdings.count > 0
      errors.add :base, %{The place could not be deleted because it is used by
        #{self.referring_sources.count} sources,
        #{self.referring_institutions.count} institutions, 
        #{self.referring_catalogues.count} catalogues and 
        #{self.referring_people.count} people
        #{self.referring_holdings.count} holdings}
      throw :abort
    end
  end
end

# A StandardTerm is a standardized keyword, ex. "Airs (instr.)"
#
# @field  <tt>term</tt> - the keyword
# @field  <tt>alternate_terms</tt> - alternate spellings for this keyword
# @field  <tt>notes</tt>
# @field  <tt>src_count</tt> - keeps track of the Source models tied to this element
# @field  other standard wf_* not shown
#
# The other functions are standard, see Catalogue for a general description

class StandardTerm < ApplicationRecord
  include AuthorityMerge
  has_and_belongs_to_many(:referring_sources, class_name: "Source", join_table: "sources_to_standard_terms")
  has_and_belongs_to_many(:referring_institutions, class_name: "Institution", join_table: "institutions_to_standard_terms")
  has_and_belongs_to_many(:referring_catalogues, class_name: "Catalogue", join_table: "catalogues_to_standard_terms")
  has_many :folder_items, as: :item, dependent: :destroy
  has_many :delayed_jobs, -> { where parent_type: "StandardTerm" }, class_name: 'Delayed::Backend::ActiveRecord::Job', foreign_key: "parent_id"
  belongs_to :user, :foreign_key => "wf_owner"
  validates_presence_of :term
  validates_uniqueness_of :term
  alias_attribute :name, :term
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
    string :term_order do
      term
    end
    text :term
    
    string :alternate_terms_order do
      alternate_terms
    end
    text :alternate_terms
    
    text :notes
    
    join(:folder_id, :target => FolderItem, :type => :integer, 
              :join => { :from => :item_id, :to => :id })
    
    integer :src_count_order, :stored => true do 
      StandardTerm.count_by_sql("select count(*) from sources_to_standard_terms where standard_term_id = #{self[:id]}")
    end
  end
  
  def check_dependencies
    if self.referring_sources.count > 0 || self.referring_institutions.count > 0 ||
         self.referring_catalogues.count > 0
      errors.add :base, %{The catalogue could not be deleted because it is used by
        #{self.referring_sources.count} sources,
        #{self.referring_institutions.count} institutions and 
        #{self.referring_catalogues.count} catalogues}
      throw :abort
    end
  end
  
  def name
    return term
  end
end

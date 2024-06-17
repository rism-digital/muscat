# A StandardTerm is a standardized keyword, ex. "Airs (instr.)"
#
# === Fields
# * <tt>term</tt> - the keyword
# * <tt>alternate_terms</tt> - alternate spellings for this keyword
# * <tt>notes</tt>
# * <tt>src_count</tt> - keeps track of the Source models tied to this element
#
# Other standard wf_* not shown
# The other functions are standard, see Publication for a general description

class StandardTerm < ApplicationRecord
  include ForeignLinks
  include AuthorityMerge
  include CommentsCleanup

  #has_and_belongs_to_many(:referring_sources, class_name: "Source", join_table: "sources_to_standard_terms")
  has_many :source_standard_term_relations, class_name: "SourceStandardTermRelation"
  has_many :referring_sources, through: :source_standard_term_relations, source: :source

  #has_and_belongs_to_many(:referring_publications, class_name: "Publication", join_table: "publications_to_standard_terms")
  has_many :publication_standard_term_relations, class_name: "PublicationStandardTermRelation"
  has_many :referring_publications, through: :publication_standard_term_relations, source: :publication

  #has_and_belongs_to_many(:referring_works, class_name: "Work", join_table: "works_to_standard_terms")
  has_many :work_standard_term_relations, class_name: "WorkStandardTermRelation"
  has_many :referring_works, through: :work_standard_term_relations, source: :work

  has_and_belongs_to_many(:referring_work_nodes, class_name: "WorkNode", join_table: "work_nodes_to_standard_terms")

  has_many :folder_items, as: :item, dependent: :destroy
  has_many :delayed_jobs, -> { where parent_type: "StandardTerm" }, class_name: 'Delayed::Backend::ActiveRecord::Job', foreign_key: "parent_id"
  belongs_to :user, :foreign_key => "wf_owner"
  validates_presence_of :term
  validates_uniqueness_of :term
  alias_attribute :name, :term
  #include NewIds
  
  before_destroy :check_dependencies, :cleanup_comments
  
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

    integer :publications_count_order, :stored => true do
      StandardTerm.count_by_sql("select count(*) from publications_to_standard_terms where standard_term_id = #{self[:id]}")
    end
  end
   
  # This function has to be implemented to use
  # the getter_function autocomplete
  # It receives a row of results from the SQL query
  def getter_function_autocomplete_label(query_row)    
    "#{term} (#{query_row[:count]})"
  end

  def name
    return term
  end

  # https://github.com/activeadmin/activeadmin/issues/7809
  # In Non-marc models we can use the default
  def self.ransackable_associations(_) = reflections.keys
  def self.ransackable_attributes(_) = attribute_names - %w[token]

end

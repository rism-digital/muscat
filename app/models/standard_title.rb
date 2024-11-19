# A StandardTerm is a standardized title for a musical work, ex. 
# Septet (from de Winter / VII Septuor)
#
# === Fields
# * <tt>title</tt> - the standardized title
# * <tt>notes</tt>
# * <tt>src_count</tt> - keeps track of the Source models tied to this element
#
# Other standard wf_* not shown
# The other functions are standard, see Publication for a general description

class StandardTitle < ApplicationRecord
  include ForeignLinks
  include AuthorityMerge
  include CommentsCleanup

  #has_and_belongs_to_many(:referring_sources, class_name: "Source", join_table: "sources_to_standard_titles")
  has_many :source_standard_title_relations, class_name: "SourceStandardTitleRelation"
  has_many :referring_sources, through: :source_standard_title_relations, source: :source

  #has_and_belongs_to_many(:referring_works, class_name: "Work", join_table: "works_to_standard_titles")
  has_many :work_standard_title_relations, class_name: "WorkStandardTitleRelation"
  has_many :referring_works, through: :work_standard_title_relations, source: :work

  has_many :inventory_item_standard_title_relations, class_name: "InventoryItemStandardTitleRelation"
  has_many :referring_inventory_items, through: :inventory_item_standard_title_relations, source: :inventory_item

  has_and_belongs_to_many(:referring_work_nodes, class_name: "WorkNode", join_table: "work_nodes_to_standard_titles")

  has_many :folder_items, as: :item, dependent: :destroy
  has_many :delayed_jobs, -> { where parent_type: "StandardTitle" }, class_name: 'Delayed::Backend::ActiveRecord::Job', foreign_key: "parent_id"
  belongs_to :user, :foreign_key => "wf_owner"
  
  validates_presence_of :title
  
  #include NewIds
  
  before_destroy :check_dependencies, :cleanup_comments
  
  #before_create :generate_new_id
  after_save :reindex
  
  attr_accessor :suppress_reindex_trigger
  alias_attribute :name, :title
  alias_attribute :id_for_fulltext, :id
  
  enum wf_stage: [ :inprogress, :published, :deleted, :deprecated ]
  enum wf_audit: [ :full, :abbreviated, :retro, :imported ]
  
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
    
    string :title_order do
      title
    end
    text :title
    
    boolean :latin_order do
      latin
    end
		
    text :notes
    text :alternate_terms
    string :alternate_terms_order do
      alternate_terms
    end
		
    text :typus
    

    boolean :is_standard, :stored => true do |st|
      (Source.solr_search do with("240a_filter", st.title) end).total > 0
    end

    boolean :is_additional, :stored => true do |st|
      (Source.solr_search do with("730a_filter", st.title) end).total > 0
    end

    boolean :is_text, :stored => true do |st|
      (Source.solr_search do with("031t_filter", st.title) end).total > 0
    end

    join(:folder_id, :target => FolderItem, :type => :integer, 
              :join => { :from => :item_id, :to => :id })
    
    integer :src_count_order, :stored => true do
      tit = title
      if !tit || tit.empty?
        puts "StandardTitle #{id_for_fulltext} has a nil .title"
        0
      else
        s = Source.solr_search do 
          any_of do
            with("031t_filter", tit)
            with("240a_filter", tit)
            with("730a_filter", tit)
          end
        end
        s.total
      end
      #StandardTitle.count_by_sql("select count(*) from sources_to_standard_titles where standard_title_id = #{self[:id]}")
    end
  end
  
  def get_typus
    res = Array.new(3)
    if (Source.solr_search do with("240a_filter", title) end).total > 0 || self.referring_sources.size > 0
      res[0] = "standard"
    end
    res[1] = (Source.solr_search do with("730a_filter", title) end).total > 0 ? "additional" : nil
    res[2] = (Source.solr_search do with("031t_filter", title) end).total > 0 ? "text" : nil
    return res.compact.join(", ")
  end
#	def get_indexed_terms
#    solr = Sunspot.session.get_connection
#    response = solr.get 'terms', :params => {:"terms.fl" => "240a_shingle_sms", :"terms.limit" => 1, :"terms.prefix" => self.title}
#    response["terms"]["240a_shingle_sms"][1]
#	end 
	 
  def name
    return title
  end

  # This function has to be implemented to use
  # the getter_function autocomplete
  # It receives a row of results from the SQL query
  def getter_function_autocomplete_label(query_row)    
    "#{title} (#{query_row[:count]})"
  end

  # If we define our own ransacker, we need this
  def self.ransackable_attributes(auth_object = nil)
    column_names + _ransackers.keys
  end

  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s }
  end

  ransacker :"is_text", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"is_standard", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"is_additional", proc{ |v| } do |parent| parent.table[:id] end  


end

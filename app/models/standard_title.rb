# A StandardTerm is a standardized title for a musical work, ex. 
# Septet (from de Winter / VII Septuor)
#
# @field <tt>title</tt> - the standardized title
# @field <tt>title_d</tt> - downcase and stripped title
# @field <tt>notes</tt>
# @field <tt>src_count</tt> - keeps track of the Source models tied to this element
# @field Other standard wf_* not shown
#
# The other functions are standard, see Catalogue for a general description

class StandardTitle < ApplicationRecord

  has_and_belongs_to_many(:referring_sources, class_name: "Source", join_table: "sources_to_standard_titles")
  has_many :folder_items, as: :item, dependent: :destroy
  has_many :delayed_jobs, -> { where parent_type: "StandardTitle" }, class_name: 'Delayed::Backend::ActiveRecord::Job', foreign_key: "parent_id"
  belongs_to :user, :foreign_key => "wf_owner"
    
  validates_presence_of :title
  
  #include NewIds
  
  before_destroy :check_dependencies
  
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
    text :title_d
    
    boolean :latin_order do
      latin
    end
		
    text :notes
    text :alternate_terms
    string :alternate_terms_order do
      alternate_terms
    end
		
    text :typus
    
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
  
  def check_dependencies
    if (self.referring_sources.count > 0)
      errors.add :base, "The standard title could not be deleted because it is used"
      throw :abort
    end
  end
   
#	def get_indexed_terms
#    solr = Sunspot.session.get_connection
#    response = solr.get 'terms', :params => {:"terms.fl" => "240a_shingle_sms", :"terms.limit" => 1, :"terms.prefix" => self.title}
#    response["terms"]["240a_shingle_sms"][1]
#	end 
	 
  def name
    return title
  end
end

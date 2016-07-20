class Work < ActiveRecord::Base
  
  belongs_to :person
  has_many :sources 
  has_many :work_incipits
  belongs_to :user, :foreign_key => "wf_owner"
  
  #include NewIds
  #before_create :generate_new_id
  before_destroy :check_dependencies
  
  attr_accessor :suppress_reindex_trigger
  after_save :reindex

  enum wf_stage: [ :inprogress, :published, :deleted ]
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
    string :title_order do
      title
    end
    text :title
    text :form
    text :notes
    
    integer :src_count_order do 
      src_count
    end
  end

  def check_dependencies
     return false if self.child_sources.count > 0
  end
  
end

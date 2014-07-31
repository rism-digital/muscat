# This model represents a publisher Institution, ad can be linked directly to a Source
# It is also one of the elements that can be contained in a folder. 
#
# === Fields
# * <tt>name</tt> - Institution's name
# * <tt>alternates</tt> - Alternate spellings for the name
# * <tt>notes</tt>
# * <tt>src_count</tt> - Incremented every time the Institution is linked to a Source
#
# the other standard wf_* fields are not shown.
# The class provides the same functionality as similar models, see Catalogue

class Institution < ActiveRecord::Base
  
  has_and_belongs_to_many :sources
  
  validates_presence_of :name  
  
  #include NewIds
  
  before_destroy :check_dependencies
  
  #before_create :generate_new_id
  after_save :reindex
  
  attr_accessor :suppress_reindex_trigger
  
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
    string :name_order do
      name
    end
    text :name
  
    text :alternates  
    text :notes
    
    integer :src_count_order do 
      src_count
    end
  end
  
  def check_dependencies
    if (self.sources.count > 0)
      errors.add :base, "The institution could not be deleted because it is used"
      return false
    end
  end
  
end

# A StandardTerm is a standardized keyword, ex. "Airs (instr.)"
#
# === Fields
# * <tt>term</tt> - the keyword
# * <tt>alternate_terms</tt> - alternate spellings for this keyword
# * <tt>notes</tt>
# * <tt>src_count</tt> - keeps track of the Source models tied to this element
#
# Other standard wf_* not shown
# The other functions are standard, see Catalogue for a general description

class StandardTerm < ActiveRecord::Base
  
  has_and_belongs_to_many :sources
    
  validates_presence_of :term
  
  validates_uniqueness_of :term
  
  include NewIds
  before_create :generate_new_id
  before_destroy :check_dependencies
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
    string :term_order do
      term
    end
    text :term
    
    string :alternate_terms_order do
      alternate_terms
    end
    text :alternate_terms
    
    text :notes
    
    integer :src_count_order do 
      src_count
    end
  end
  
  def check_dependencies
    if (self.sources.count > 0)
      errors.add :base, "The standard term could not be deleted because it is used"
      return false
    end
  end
  
end

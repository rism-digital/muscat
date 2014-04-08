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
    
  before_destroy :check_dependencies
    
  def check_dependencies
    if (self.sources.count > 0)
      errors.add :base, "The institution could not be deleted because it is used"
      return false
    end
  end
  
end

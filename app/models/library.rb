# Describes a Library linked with a Source
#
# === Fields
# * <tt>siglum</tt> - RISM sigla of the lib
# * <tt>name</tt> -  Fullname of the lib
# * <tt>address</tt>
# * <tt>url</tt>
# * <tt>phone</tt> 
# * <tt>email</tt>
# * <tt>src_count</tt> - The number of manuscript that reference this lib.
#
# the other standard wf_* fields are not shown.
# The class provides the same functionality as similar models, see Catalogue

class Library < ActiveRecord::Base
  
  has_and_belongs_to_many :sources
    
  validates_presence_of :siglum    
  
  validates_uniqueness_of :siglum
    
  before_destroy :check_dependencies
    
  def check_dependencies
    if (self.sources.count > 0)
      errors.add :base, "The library could not be deleted because it is used"
      return false
    end
  end
  
end

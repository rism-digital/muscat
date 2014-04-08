# Describes any kind of liturgical feast (e.g. Adventus) linked wit a Source
#
# === Fields
# * <tt>name</tt> - Name of this particular feast
# * <tt>notes</tt>
# * <tt>src_count</tt> - The number of sources that reference this lib.
#
# the other standard wf_* fields are not shown.
# The class provides the same functionality as similar models, see Catalogue

class LiturgicalFeast < ActiveRecord::Base
  
  has_and_belongs_to_many :sources
    
  validates_presence_of :name
  
  validates_uniqueness_of :name
    
  before_destroy :check_dependencies
    
  def check_dependencies
    return false if self.sources.count > 0
  end
  
end

# A Person is a physical person tied to one or more Sources.
# a person reference is generally stored also in the source's marc data
#
# === Fields
# * <tt>full_name</tt> - Full name of the person: Second name, Name
# * <tt>full_name_d</tt> - Downcase with UTF chars stripped 
# * <tt>life_dates</tt> - Dates in the form xxxx-xxxx
# * <tt>birth_place</tt>
# * <tt>gender</tt> - 0 = male, 1 = female
# * <tt>composer</tt> - 1 =  it is a composer
# * <tt>source</tt> - Source from where the bio info comes from
# * <tt>alternate_names</tt> - Alternate spelling of the name
# * <tt>alternate_dates</tt> - Alternate birth/death dates if uncertain 
# * <tt>comments</tt>
# * <tt>src_count</tt> - Incremented every time a Source tied to this person
# * <tt>hls_id</tt> - Used to match this person with the its biografy at HLS (http://www.hls-dhs-dss.ch/)
#
# Other wf_* fields are not shown

class Person < ActiveRecord::Base
  
  has_many :works
  has_and_belongs_to_many :sources
  
  validates_presence_of :full_name  
  
  before_destroy :check_dependencies
  
  # before_destroy, will delete Person only if it has no Source and no Work
  def check_dependencies
    return false if self.sources.count > 0
    return false if self.works.count > 0
  end
  
end

# A Place describes a physical place - like a city - where a Source is found
#
# === Fields
# * <tt>name</tt>
# * <tt>country</tt>
# * <tt>district</tt>
# * <tt>notes</tt>
# * <tt>src_count</tt>
#
# Usual wf_* fields are not shown

class Place < ActiveRecord::Base
  
  has_and_belongs_to_many :sources
    
  validates_presence_of :name
  
  validates_uniqueness_of :name
    
  before_destroy :check_dependencies
    
  def check_dependencies
    return false if self.sources.count > 0
  end
  
end

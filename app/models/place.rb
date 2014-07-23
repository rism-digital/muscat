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
    string :name_order do
      name
    end
    text :name
    
    string :country_order do
      country
    end
    text :country
    
    text :notes
    text :district
    
    integer :src_count_order do 
      src_count
    end
  end
  
  def check_dependencies
    if (self.sources.count > 0)
      errors.add :base, "The place could not be deleted because it is used"
      return false
    end
  end
  
end

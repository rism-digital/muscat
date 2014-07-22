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
  resourcify 
  has_many :works
  has_and_belongs_to_many :sources
  
  composed_of :marc, :class_name => "MarcPerson", :mapping => %w(marc_source)
  
  validates_presence_of :full_name  
  
  before_destroy :check_dependencies
  before_save :set_object_fields
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
    string :full_name_order do
      full_name
    end
    text :full_name
    text :full_name_d
    
    string :life_dates_order do
      life_dates
    end
    text :life_dates
    
    text :birth_place
    text :source
    text :alternate_names
    text :alternate_dates
    
    integer :src_count_order do 
      src_count
    end
  end
  
  # before_destroy, will delete Person only if it has no Source and no Work
  def check_dependencies
    if (self.sources.count > 0) || (self.works.count > 0)
      errors.add :base, "The person could not be deleted because it is used"
      return false
    end
  end
  
  def set_object_fields

    # update last transcation
    marc.update_005
    
    # source id
    ##marc_source_id = marc.get_marc_source_id
    ##self.id = marc_source_id if marc_source_id
    # FIXME how do we generate ids?
    #self.marc.set_id self.id

    # std_title
    self.full_name, self.full_name_d = marc.get_full_name
    
    self.marc_source = self.marc.to_marc
  end
  
end

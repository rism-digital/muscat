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
  resourcify
  
  has_and_belongs_to_many :sources
  has_and_belongs_to_many :institutions
  has_and_belongs_to_many :workgroups
  has_many :folder_items, :as => :item
    
  validates_presence_of :siglum    
  
  validates_uniqueness_of :siglum
  
  #include NewIds
  
  before_destroy :check_dependencies
  
  #before_create :generate_new_id
  after_save :reindex
  after_create :update_workgroups
  
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
    string :siglum_order do
      siglum
    end
    text :siglum
    
    string :name_order do
      name
    end
    text :name
    
    text :address
    text :url
    text :phone
    text :email
    
    join(:folder_id, :target => FolderItem, :type => :integer, 
              :join => { :from => :item_id, :to => :id })
    
    integer :src_count_order do 
      src_count
    end
  end
  
  def check_dependencies
    if (self.sources.count > 0)
      errors.add :base, "The library could not be deleted because it is used"
      return false
    end
  end

  def update_workgroups
    Workgroup.all.each do |wg|
      if Regexp.new(wg.libpatterns).match(self.siglum)
        wg.save
      end
    end
  end
  
end

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

class Institution < ActiveRecord::Base
  resourcify
  
  has_and_belongs_to_many :sources
  #has_many :folder_items, :as => :item
  has_and_belongs_to_many :institutions
  has_and_belongs_to_many :workgroups
    
  composed_of :marc, :class_name => "MarcInstitution", :mapping => %w(marc_source)
  
  #validates_presence_of :siglum    
  
  validates_uniqueness_of :siglum, :allow_nil => true
  
  #include NewIds
  
  before_destroy :check_dependencies
  
  #before_create :generate_new_id
  after_save :reindex
  after_create :update_workgroups
  
  before_validation :set_object_fields
  
  attr_accessor :suppress_reindex_trigger

  # Suppresses the solr reindex
  def suppress_reindex
    self.suppress_reindex_trigger = true
  end
  
  def scaffold_marc
    return if self.marc_source != nil  
    return if self.suppress_scaffold_marc_trigger == true
  
    new_marc = MarcInstitution.new(File.read("#{Rails.root}/config/marc/#{RISM::BASE}/library/default.marc"))
    new_marc.load_source true
    
    new_100 = MarcNode.new("institution", "110", "", "1#")
    new_100.add_at(MarcNode.new("institution", "a", self.full_name, nil), 0)
    
    pi = new_marc.get_insert_position("100")
    new_marc.root.children.insert(pi, new_100)

    if self.id != nil
      new_marc.set_id self.id
    end
    
    self.marc_source = new_marc.to_marc
    self.save!
  end

  def set_object_fields
    # This is called always after we tried to add MARC
    # if it was suppressed we do not update it as it
    # will be nil
    return if marc_source == nil

    # update last transcation
    marc.update_005
    
    # If the source id is present in the MARC field, set it into the
    # db record
    # if the record is NEW this has to be done after the record is created
    marc_source_id = marc.get_marc_source_id
    # If 001 is empty or new (__TEMP__) let the DB generate an id for us
    # this is done in create(), and we can read it from after_create callback
    self.id = marc_source_id if marc_source_id and marc_source_id != "__TEMP__"

    # std_title
    self.name, self.place = marc.get_name_and_place
    self.address, self.url = marc.get_address_and_url
    self.siglum = marc.get_siglum
    self.marc_source = self.marc.to_marc
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
      errors.add :base, "The institution could not be deleted because it is used"
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

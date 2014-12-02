# The Catalogue model describes a basic bibliograpfic catalog
# and is used to link Sources with its bibliographical info
#
# === Fields
# * <tt>name</tt> - Abbreviated name of the catalogue
# * <tt>author</tt> - Author
# * <tt>description</tt> - Full title
# * <tt>revue_title</tt> - if printed in a journal, the journal's title
# * <tt>volume</tt> - as above, the journal volume
# * <tt>place</tt>
# * <tt>date</tt>
# * <tt>pages</tt>
#
# === Relations
# * many to many with Sources

class Catalogue < ActiveRecord::Base
  resourcify

  has_and_belongs_to_many :sources
  
  composed_of :marc, :class_name => "MarcCatalogue", :mapping => %w(marc_source)
  
  ##include NewIds
  
  before_destroy :check_dependencies
  
  ##before_create :generate_new_id
  after_save :reindex
  
  attr_accessor :suppress_reindex_trigger
  
  # Suppresses the solr reindex
  def suppress_reindex
    self.suppress_reindex_trigger = true
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
    self.place, self.date = marc.get_place_and_date
    self.name = marc.get_short_title
    self.title = marc.get_title
    self.author = marc.get_author
    self.marc_source = self.marc.to_marc
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
    
    string :author_order do
      author
    end
    text :author
    
    text :description
    text :revue_title
    text :volume
    text :place
    text :date
    text :pages
    
    integer :src_count_order do 
      src_count
    end
  end
  
  def check_dependencies
    if (self.sources.count > 0)
      errors.add :base, "The catalogue could not be deleted because it is used"
      return false
    end
  end
  
  def self.find_recent_updated(limit)
      where("updated_at > ?", 5.days.ago).limit(limit)
  end
  
  def self.find_recent_created(limit)
      where("created_at > ?", 5.days.ago).limit(limit)
  end

end

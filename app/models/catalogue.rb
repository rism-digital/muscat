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
  
  has_and_belongs_to_many :sources
  
  validates_presence_of :name  
  
  validates_uniqueness_of :name
  
  ##include NewIds
  
  before_destroy :check_dependencies
  
  ##before_create :generate_new_id
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
  
end

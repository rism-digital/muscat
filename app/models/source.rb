## A Source is the base entity that is catalogued in RISM. 
#
# All the data is stored in the manuscripts
# table in a TEXT blob as MARC data. Fields that are important for brief display are
# mapped directly to fields in manuscripts and used exclusively for that purpose.  Any browsing or
# editting is performed on the marc record itself which is stored in the "source" field.  This field
# is aggregated to the Marc class which understands the marc format.  All operations on the marc record 
# are handled by the Marc class.  See that class for more details.
# 
# === Fields
# * <tt>id</tt> - numerical RISM id
# * <tt>ms_lib_siglums</tt> - List of the library siglums, Library_id is nost stored anymore here, we use LibrariesSource for many-to-many 
# * <tt>record_type</tt> - set to 1 id the ms. is anonymous, set to 2 if the ms. is a holding record
# * <tt>std_title</tt> - Standard Title
# * <tt>std_title_d</tt> - Standard title, downcase, with all UTF chars stripped (and substituted by ASCII chars)
# * <tt>composer</tt> - Composer name
# * <tt>composer_d</tt> - Composer, downcase, as standard title
# * <tt>title</tt> - Title on manuscript (non standardized)
# * <tt>title_d</tt> - Title on ms, downcase, chars stripped as in std_title_d and composer_d
# * <tt>shelf_mark</tt> - source shelfmark
# * <tt>language</tt> - Language of the text (if present) in the ms.
# * <tt>date_from</tt> - First date on ms.
# * <tt>date_to</tt> - Last date on ms.
# * <tt>source</tt> - All the MARC data
# (standard wf_* fields are not shown)
#
# The Source class has also a belongs_to and has_many relationship to itself for linking parent <-> children sources,
# for example with collection and collection items or with bibligraphical and holding records for prints
#
# Database is UTF8 and collation utf8_general_ci which is NOT the strict UTF collation but rather one that
# is more suitable for english speakers.



class Source < ActiveRecord::Base
  
  # include the override for group_values
  require 'solr_search.rb'
  
  belongs_to :source
  has_many :sources
  has_and_belongs_to_many :libraries
  has_and_belongs_to_many :people
  has_and_belongs_to_many :standard_titles
  has_and_belongs_to_many :standard_terms
  has_and_belongs_to_many :institutions
  has_and_belongs_to_many :catalogues
  has_and_belongs_to_many :liturgical_feasts
  has_and_belongs_to_many :places
  has_and_belongs_to_many :works
  
  composed_of :marc, :class_name => "Marc", :mapping => %w(marc_source)
  alias_attribute :id_for_fulltext, :id
  
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
    
    text :id_fulltext do
      id_for_fulltext
    end
    
    text :source_id
    
    string :std_title_order do 
      std_title
    end
    text :std_title
    text :std_title_d
    
    string :composer_order do 
      composer
    end
    text :composer
    text :composer_d
    
    text :marc_source
    
    string :title_order do 
      title
    end
    text :title
    text :title_d
    
    string :shelf_mark_order do 
      shelf_mark
    end
    text :shelf_mark
    
    string :lib_siglum_order do
      lib_siglum
    end
    text :lib_siglum
    
    integer :date_from
    integer :date_to
    
    integer :catalogues, :multiple => true do
          catalogues.map { |catalogue| catalogue.id }
    end
    
    integer :people, :multiple => true do
          people.map { |person| person.id }
    end
    
    integer :libraries, :multiple => true do
          libraries.map { |library| library.id }
    end
    
    integer :institutions, :multiple => true do
          institutions.map { |institution| institution.id }
    end
    
    integer :liturgical_feasts, :multiple => true do
          liturgical_feasts.map { |lf| lf.id }
    end
    
    integer :standard_terms, :multiple => true do
          standard_terms.map { |st| st.id }
    end
    
    integer :standard_titles, :multiple => true do
          standard_titles.map { |stit| stit.id }
    end
    
    integer :works, :multiple => true do
          works.map { |work| work.id }
    end
  end
    
  def check_dependencies
    if (self.sources.count > 0)
      errors.add :base, "The source could not be deleted because it is used"
      return false
    end
  end
    
end

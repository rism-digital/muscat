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
  include MarcIndex
  resourcify
  
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
  
  composed_of :marc, :class_name => "MarcSource", :mapping => %w(marc_source)
  alias_attribute :id_for_fulltext, :id
  
  # FIXME id generation
  before_destroy :check_dependencies
  
  before_save :set_object_fields
  before_create :generate_id
  after_save :destroy_links, :create_links, :reindex
  before_destroy :destroy_links
  
  # alias for holding records
  alias_attribute :ms_condition, :title  
  alias_attribute :image_urls, :title_d
  alias_attribute :urls, :composer_d
  # For bibliografic records in A/1, the old rism id goes into ms_no
  alias_attribute :book_id, :shelf_mark
  
  attr_accessor :suppress_reindex_trigger
  attr_accessor :suppress_recreate_trigger
  attr_accessor :suppress_update_77x_trigger
  attr_accessor :suppress_update_count_trigger
  
  # Sets the initial values for the ms. on creation. In particular it creates a id,
  # made of BASE_ID + USER_RISM_NO + maximum id
  # for holding records, made of BASE_HOLDING_ID + maximum id 
  def generate_id
    if !self.id or self.id == "__TEMP__" or self.id == "__TEMP_HOLDING__"
      # lower and upper boundary of the server
      user = 9 #
      lowest_base_id = "#{RISM::BASE_ID.to_i + user}000000".to_i
      upper_base_id = ((RISM::BASE_ID.to_i + 1 + user).to_s + "000000").to_i  
      if self.id == "__TEMP_HOLDING__"
        lowest_base_id = "#{RISM::BASE_HOLDING_ID}000000000".to_i
        upper_base_id =  "#{RISM::BASE_HOLDING_ID}999999999".to_i
      end
      highest_id = Source.maximum(:id, :conditions => ['id < ?', ("%014d" % upper_base_id)]).to_i + 1
      # we want at least the lower boundary
      highest_id = lowest_base_id if highest_id < lowest_base_id
      self.id = highest_id
      self.marc.set_id self.id
      self.marc_source = self.marc.to_marc
    end
  end
  
  # Suppresses the recreation of the links with foreign MARC elements
  # (es libs, people, ...) on saving
  def suppress_recreate
    self.suppress_recreate_trigger = true
  end  
  
  def suppress_update_77x
    self.suppress_update_77x_trigger = true
  end
  
  def suppress_update_count
    self.suppress_update_count_trigger = true
  end
  
  # On creation, it inspects this Ms ad created all the links to
  # Person, Title, StandardTerm, Institution, Catalogue, LiturgicalFeast, Place and Library
  # Used for example when importing marc records to tie all these elements with the ms.
  def create_links
    return if self.suppress_recreate_trigger == true   
    marc.get_all_foreign_associations.each do |object_id, object|
      # object_id has the form ClassName-ext_id     
      # FIXME find a dynamic way to do this!
      if object.is_a? Person
        people << object
      elsif object.is_a? StandardTitle
        standard_titles << object
      elsif object.is_a? StandardTerm
        standard_terms << object
      elsif object.is_a? Catalogue
        catalogues << object
      elsif object.is_a? LiturgicalFeast
        liturgical_feasts << object
      elsif object.is_a? Place
        places << object
      elsif object.is_a? Institution
        institutions << object 
      elsif object.is_a? Library
        libraries << object
# FIXME enable if works will be ported, see below in destroy_links also
#      elsif object.is_a? Work
#        #works << object
#        mw = SourcesWork.new(:work_id => object.id, :manuscript_id => self.id)
#        mw.suppress_update
#        mw.save
#        w = Work.find_by_id( object.id )
#        w.suppress_reindex
#        w.update_attribute( :src_count, w.sources.size )
      elsif object.is_a? Source
        # nothing to do. Everything is done in set_object_fields
      else
        raise "Unknown foregin object!!" 
      end
      
      if !object.is_a? Source and self.suppress_update_count_trigger != true
        o = object.class.send("find_by_id", object.id)
        o.suppress_reindex
        o.update_attribute(:src_count, o.sources.count)
      end
    end
    # update the parent manuscript when having 773/772 relationships
    marc.update_77x unless self.suppress_update_77x_trigger == true 
  end
  
  # Deletes all the links from Person, Title, StandardTerm, Institution, Catalogue, LiturgicalFeast, Place and Library
  def destroy_links
    return if self.suppress_recreate_trigger == true
    [ people, standard_titles, standard_terms, institutions, catalogues, liturgical_feasts, libraries, places].each do |foreign|
      links = foreign.all
      foreign.delete(links)
      
      if self.suppress_update_count_trigger != true
        links.each do |link|
          ## RZ TODO CAVEAT test me!
          item = eval(link.class.model_name).find_by_id( link.id )
          item.suppress_reindex
          item.update_attribute( :src_count, item.sources.count )
        end
      end
    end
# FIXME add support for works, need to port the ManuscriptsWork model, if this will be
# ever ported
#    # Works need to be done by hand it seems, calling .delete() creates an invalid query
#    items = SourcesWork.find(:all, :conditions => ["source_id = ?", self.id]) 
#    SourcesWork.delete_all(["source_id = ?", self.id]) # delete and not destroy so we do not call before_destroy
#    items.each do |i|
#      w = Work.find_by_id( i.work_id )
#      w.suppress_reindex
#      w.update_attribute( :src_count, w.sources.count )
#    end
    
  end
  
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
    text :std_title, :stored => true
    text :std_title_d
    
    string :composer_order do 
      composer
    end
    text :composer, :stored => true
    text :composer_d
    
    text :marc_source
    
    string :title_order do 
      title
    end
    text :title, :stored => true
    text :title_d
    
    string :shelf_mark_order do 
      shelf_mark
    end
    text :shelf_mark, :stored => true
    
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
    
    integer :places, :multiple => true do
          places.map { |place| place.id }
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
    
    # It seems this thig here can *NOT*
    # be put in a funciton, because
    # I have the pointer to the current scope only
    # into the "string do" block
    IndexConfig.get_fields("source").each do |k, v|
      store = v && v.has_key?(:store) ? v[:store] : false
      boost = v && v.has_key?(:boost) ? v[:boost] : 1.0
      type = v && v.has_key?(:type) ? v[:type] : 'string'
      
      string k, :multiple => true, :stored => store do
        marc_index_tag(k, v, marc, self)
      end
    end
    
  end
    
  def check_dependencies
    if (self.sources.count > 0)
      errors.add :base, "The source could not be deleted because it is used"
      return false
    end
  end
    
  # Method: set_object_fields
  # Parameters: none
  # Return: none
  #
  # Brings in the real data into the fields from marc structure
  # seeing as all other models are involved in x-many-x relationships and ids
  # are stored outside of the manuscripts table.
  # 
  # Fields are:
  #  std_title
  #  std_title_d
  #  composer
  #  composer_d
  #  ms_title
  #  ms_title_d
  # 
  # the _d variant fields store a normalized lower case version with accents removed
  # the _d columns are used for western dictionary sorting in list forms
  def set_object_fields

    # update last transcation
    marc.update_005
    
    # source id
    ##marc_source_id = marc.get_marc_source_id
    ##self.id = marc_source_id if marc_source_id
    # FIXME how do we generate ids?
    #self.marc.set_id self.id
    
    # parent source
    parent = marc.get_parent
    self.source_id = parent.id if parent
    
    # record type
    self.record_type = 2 if marc.is_holding?
    
    # std_title
    self.std_title, self.std_title_d = marc.get_std_title
    
    # composer
    self.composer, self.composer_d = marc.get_composer
    
    # siglum and ms_no
    # in A/1 we do not have 852 in the bibliographic data
    # instead we store in ms_no the Book RISM ID (old rism id)
    if RISM::BASE == "a1" and record_type == 0
      self.book_id = marc.get_book_rism_id
    else
      self.lib_siglum, self.shelf_mark = marc.get_siglum_and_shelf_mark
    end
    
    # ms_title for bibliographic records
    self.title, self.title_d = marc.get_source_title if self.record_type != 2
    
    # physical_condition and urls for holding records
    self.ms_condition, self.urls, self.image_urls = marc.get_ms_condition_and_urls if self.record_type == 2
    
    # miscallaneous
    self.language, self.date_from, self.date_to = marc.get_miscellaneous_values

    self.marc_source = self.marc.to_marc
  end
  
end

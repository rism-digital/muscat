# The Publication model describes a basic secondary literature entry
# and is used to link Sources with its bibliographical info
#
# === Fields
# * <tt>name</tt> - Abbreviated name of the publication
# * <tt>author</tt> - Author
# * <tt>title</tt> - Full title
# * <tt>journal</tt> - if printed in a journal, the journal's title
# * <tt>volume</tt> - as above, the journal volume
# * <tt>place</tt>
# * <tt>date</tt>
# * <tt>pages</tt>
# * <tt>source</tt> - All the MARC data
# (standard wf_* fields are not shown)
#
# === Relations
# * many to many with Sources

class Publication < ApplicationRecord

  # class variables for storing the user name and the event from the controller
  @last_user_save
  attr_accessor :last_user_save
  @last_event_save
  attr_accessor :last_event_save

  has_paper_trail :on => [:update, :destroy], :only => [:marc_source, :wf_stage, :work_catalogue], :if => Proc.new { |t| VersionChecker.save_version?(t) }

  include ForeignLinks
  include MarcIndex
  include AuthorityMerge
  include CommentsCleanup
  include ComposedOfReimplementation
  include ThroughAssociations
  resourcify

  #has_and_belongs_to_many(:referring_sources, class_name: "Source", join_table: "sources_to_publications")
  has_many :source_publication_relations, class_name: "SourcePublicationRelation"
  has_many :referring_sources, through: :source_publication_relations, source: :source

  #has_and_belongs_to_many(:referring_institutions, class_name: "Institution", join_table: "institutions_to_publications")
  has_many :institution_publication_relations, class_name: "InstitutionPublicationRelation"
  has_many :referring_institutions, through: :institution_publication_relations, source: :institution

  #has_and_belongs_to_many(:referring_people, class_name: "Person", join_table: "people_to_publications")
  has_many :person_publication_relations, class_name: "PersonPublicationRelation"
  has_many :referring_people, through: :person_publication_relations, source: :person
  
  #has_and_belongs_to_many(:referring_holdings, class_name: "Holding", join_table: "holdings_to_publications")
  has_many :holding_publication_relations, class_name: "HoldingPublicationRelation"
  has_many :referring_holdings, through: :holding_publication_relations, source: :holding
  
  #has_and_belongs_to_many(:referring_works, class_name: "Work", join_table: "works_to_publications")
  has_many :work_publication_relations, class_name: "WorkPublicationRelation"
  has_many :referring_works, through: :work_publication_relations, source: :work
  
  #has_and_belongs_to_many(:referring_inventory_items, class_name: "InventoryItem", join_table: "inentory_items_to_publications")
  has_many :inventory_item_publication_relations, class_name: "InventoryItemPublicationRelation"
  has_many :referring_inventory_items, through: :inventory_item_publication_relations, source: :inventory_item

  #has_and_belongs_to_many :people, join_table: "publications_to_people"
  has_many :publication_person_relations
  has_many :people, through: :publication_person_relations

  #has_and_belongs_to_many :institutions, join_table: "publications_to_institutions"
  has_many :publication_institution_relations
  has_many :institutions, through: :publication_institution_relations

  #has_and_belongs_to_many :places, join_table: "publications_to_places"
  has_many :publication_place_relations
  has_many :places, through: :publication_place_relations

  #has_and_belongs_to_many :standard_terms, join_table: "publications_to_standard_terms"
  has_many :publication_standard_term_relations
  has_many :standard_terms, through: :publication_standard_term_relations

  has_many :folder_items, as: :item, dependent: :destroy
  has_many :delayed_jobs, -> { where parent_type: "Publication" }, class_name: 'Delayed::Backend::ActiveRecord::Job', foreign_key: "parent_id"
  belongs_to :user, :foreign_key => "wf_owner"

  # This is the forward link
#  has_and_belongs_to_many(:publications,
#    :class_name => "Publication",
#    :foreign_key => "publication_a_id",
#    :association_foreign_key => "publication_b_id",
#    join_table: "publications_to_publications")

  # This is the backward link
#  has_and_belongs_to_many(:referring_publications,
#    :class_name => "Publication",
#    :foreign_key => "publication_b_id",
#    :association_foreign_key => "publication_a_id",
#    join_table: "publications_to_publications")

  has_many :publication_relations, foreign_key: "publication_a_id"
  has_many :publications, through: :publication_relations, source: :publication_b
  # And this is the one coming back
  has_many :referring_publication_relations, class_name: "PublicationRelation", foreign_key: "publication_b_id"
  has_many :referring_publications, through: :referring_publication_relations, source: :publication_a

  composed_of_reimplementation :marc, :class_name => "MarcPublication", :mapping => %w(marc_source to_marc)

  ##include NewIds
  before_destroy :check_dependencies, :cleanup_comments, :update_links

  before_save :set_object_fields
  after_create :scaffold_marc, :fix_ids
  after_initialize :after_initialize
  after_save :update_links, :reindex

  attr_accessor :suppress_reindex_trigger
  attr_accessor :suppress_recreate_trigger
  attr_accessor :suppress_scaffold_marc_trigger
  attr_accessor :suppress_update_count_trigger

  alias_attribute :id_for_fulltext, :id
  alias_attribute :name, :short_name

  enum :wf_stage, [ :inprogress, :published, :deleted, :deprecated ]
  enum :wf_audit, [ :full, :abbreviated, :retro, :imported ]
  enum :work_catalogue, [:not_work_catalogue, :work_catalogue_in_preparation, :work_catalogue_partial, :work_catalogue_complete, :work_catalogue_alternate]

  def after_initialize
    @last_user_save = nil
    @last_event_save = "update"
  end

  # Suppresses the recreation of the links with foreign MARC elements
  # (es libs, people, ...) on saving
  def suppress_recreate
    self.suppress_recreate_trigger = true
  end

  def suppress_scaffold_marc
    self.suppress_scaffold_marc_trigger = true
  end

  def suppress_update_count
    self.suppress_update_count_trigger = true
  end

  def update_links
    return if self.suppress_recreate_trigger == true

    allowed_relations = ["institutions", "people", "places", "publications", "standard_terms"]
    recreate_links(marc, allowed_relations)
  end

  def scaffold_marc
    return if self.marc_source != nil
    return if self.suppress_scaffold_marc_trigger == true

    new_marc = MarcPublication.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/publication/default.marc")))
    new_marc.load_source false

    #new_100 = MarcNode.new("publication", "100", "", "1#")
    #new_100.add_at(MarcNode.new("publication", "a", self.author, nil), 0)

    #new_marc.root.children.insert(new_marc.get_insert_position("100"), new_100)

    # save name
    if self.short_name
      node = MarcNode.new("publication", "210", "", "##")
      node.add_at(MarcNode.new("publication", "a", self.short_name, nil), 0)

      new_marc.root.children.insert(new_marc.get_insert_position("210"), node)
    end

    # save decription
    if self.title
      node = MarcNode.new("publication", "240", "", "##")
      node.add_at(MarcNode.new("publication", "a", self.title, nil), 0)

      new_marc.root.children.insert(new_marc.get_insert_position("240"), node)
    end

    # save date and place
    if self.date || self.place
      node = MarcNode.new("publication", "260", "", "##")
      node.add_at(MarcNode.new("publication", "c", self.date, nil), 0) if self.date
      node.add_at(MarcNode.new("publication", "a", self.place, nil), 0) if self.place

      new_marc.root.children.insert(new_marc.get_insert_position("260"), node)
    end

    # save journal
    if self.journal
      node = MarcNode.new("publication", "760", "", "0#")
      node.add_at(MarcNode.new("publication", "t", self.journal, nil), 0)

      new_marc.root.children.insert(new_marc.get_insert_position("760"), node)
    end

    if self.id != nil
      new_marc.set_id self.id
    end

    self.marc_source = new_marc.to_marc
    self.save!
  end

  # Suppresses the solr reindex
  def suppress_reindex
    self.suppress_reindex_trigger = true
  end

  def reindex
    return if self.suppress_reindex_trigger == true
    self.index
  end

  searchable :auto_index => false do |sunspot_dsl|
    sunspot_dsl.integer :id, stored: true
    sunspot_dsl.text :id_text do
      id_for_fulltext
    end

    sunspot_dsl.string :short_name_order do
      short_name
    end
    sunspot_dsl.text :short_name

    sunspot_dsl.string :author_order do
      author
    end
    sunspot_dsl.text :author

    sunspot_dsl.text :title
    sunspot_dsl.string :title_order do
      title
    end

    sunspot_dsl.text :journal
    sunspot_dsl.string :journal_order do
      journal
    end

    sunspot_dsl.text :volume
    sunspot_dsl.text :place
    sunspot_dsl.text :date
    sunspot_dsl.string :date_order do
      date
    end

    sunspot_dsl.text :pages

    sunspot_dsl.integer :wf_owner
    sunspot_dsl.string :wf_stage
    sunspot_dsl.time :updated_at
    sunspot_dsl.time :created_at

    # We could also use the enum value here (0...3)
    # but using the symbol seems less obscure
    sunspot_dsl.string :work_catalogue
    sunspot_dsl.string :work_catalogue_order do
      work_catalogue
    end

    sunspot_dsl.join(:folder_id, :target => FolderItem, :type => :integer,
              :join => { :from => :item_id, :to => :id })

    sunspot_dsl.text :text do |s|
      s.marc.to_raw_text
    end

    sunspot_dsl.integer(:src_count_order, :stored => true) {through_associations_source_count}
    sunspot_dsl.integer(:referring_objects_order, stored: true) {through_associations_exclude_source_count}

    MarcIndex::attach_marc_index(sunspot_dsl, self.to_s.downcase)
  end

  # Method: set_object_fields
  # Parameters: none
  # Return: none
  #
  # Brings in the real data into the fields from marc structure
  # seeing as all other models are involved in x-many-x relationships and ids
  # are stored outside of the publications table.
  #
  # the _d variant fields store a normalized lower case version with accents removed
  # the _d columns are used for western dictionary sorting in list forms
  def set_object_fields
    # This is called always after we tried to add MARC
    # if it was suppressed we do not update it as it
    # will be nil
    return if marc_source == nil

    # If the source id is present in the MARC field, set it into the
    # db record
    # if the record is NEW this has to be done after the record is created
    marc_source_id = marc.get_marc_source_id
    # If 001 is empty or new (__TEMP__) let the DB generate an id for us
    # this is done in create(), and we can read it from after_create callback
    self.id = marc_source_id if marc_source_id and marc_source_id != "__TEMP__"

    # std_title
    self.place, self.date = marc.get_place_and_date
    self.short_name = marc.get_name
    self.title = marc.get_title
    self.author = marc.get_author
    self.journal = marc.get_journal
    self.marc_source = self.marc.to_marc
  end

  def fix_ids
    #generate_new_id
    # If there is no marc, do not add the id
    return if marc_source == nil

    # The ID should always be sync'ed if it was not generated by the DB
    # If it was scaffolded it is already here
    # If we imported a MARC record into Person, it is already here
    # THis is basically only for when we have a new item from the editor
    marc_source_id = marc.get_marc_source_id
    if !marc_source_id or marc_source_id == "__TEMP__"

      self.marc.set_id self.id
      self.marc_source = self.marc.to_marc
      # this is the new version
      PaperTrail.request(enabled: false) do
        save
      end
    end
  end

  def autocomplete_label(query_row = nil) 
    aut = (author and !author.empty? ? author : nil)
    tit = (title and !title.empty? ? title : nil)
    dat = (date and !date.empty? ? date : nil)

    infos = [aut, dat, tit].compact.join(", ")

    return "#{self.short_name} (#{query_row[:count]}): #{infos}".truncate(100)  if query_row
    return "#{self.short_name}: #{infos}".truncate(110)
  end

  def getter_function_autocomplete_label(query_row)    
    autocomplete_label(query_row)
  end

  # If we define our own ransacker, we need this
  def self.ransackable_attributes(auth_object = nil)
    column_names + _ransackers.keys
  end

  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s }
  end

  ransacker :"240g", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"260b", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"505t", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"100a_or_700a", proc{ |v| } do |parent| parent.table[:id] end
    
end

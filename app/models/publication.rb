# The Publication model describes a basic secondary literature entry
# and is used to link Sources with its bibliographical info
#
# === Fields
# * <tt>name</tt> - Abbreviated name of the publication
# * <tt>author</tt> - Author
# * <tt>description</tt> - Full title
# * <tt>revue_title</tt> - if printed in a journal, the journal's title
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

  has_paper_trail :on => [:update, :destroy], :only => [:marc_source, :wf_stage], :if => Proc.new { |t| VersionChecker.save_version?(t) }

  include ForeignLinks
  include MarcIndex
  include AuthorityMerge
  resourcify

  has_and_belongs_to_many(:referring_sources, class_name: "Source", join_table: "sources_to_publications")
  has_and_belongs_to_many(:referring_institutions, class_name: "Institution", join_table: "institutions_to_publications")
  has_and_belongs_to_many(:referring_people, class_name: "Person", join_table: "people_to_publications")
  has_and_belongs_to_many(:referring_holdings, class_name: "Holding", join_table: "holdings_to_publications")
  has_and_belongs_to_many :people, join_table: "publications_to_people"
  has_and_belongs_to_many :institutions, join_table: "publications_to_institutions"
  has_and_belongs_to_many :places, join_table: "publications_to_places"
  has_and_belongs_to_many :standard_terms, join_table: "publications_to_standard_terms"
  has_many :folder_items, as: :item, dependent: :destroy
  has_many :delayed_jobs, -> { where parent_type: "Publication" }, class_name: 'Delayed::Backend::ActiveRecord::Job', foreign_key: "parent_id"
  belongs_to :user, :foreign_key => "wf_owner"

  # This is the forward link
  has_and_belongs_to_many(:publications,
    :class_name => "Publication",
    :foreign_key => "publication_a_id",
    :association_foreign_key => "publication_b_id",
    join_table: "publications_to_publications")

  # This is the backward link
  has_and_belongs_to_many(:referring_publications,
    :class_name => "Publication",
    :foreign_key => "publication_b_id",
    :association_foreign_key => "publication_a_id",
    join_table: "publications_to_publications")

  composed_of :marc, :class_name => "MarcPublication", :mapping => %w(marc_source to_marc)

  ##include NewIds
  before_destroy :check_dependencies

  before_save :set_object_fields
  after_create :scaffold_marc, :fix_ids
  after_initialize :after_initialize
  after_save :update_links, :reindex

  attr_accessor :suppress_reindex_trigger
  attr_accessor :suppress_recreate_trigger
  attr_accessor :suppress_scaffold_marc_trigger

  alias_attribute :id_for_fulltext, :id
  alias_attribute :name, :short_name

  enum wf_stage: [ :inprogress, :published, :deleted, :deprecated ]
  enum wf_audit: [ :full, :abbreviated, :retro, :imported ]

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
    if self.description
      node = MarcNode.new("publication", "240", "", "##")
      node.add_at(MarcNode.new("publication", "a", self.description, nil), 0)

      new_marc.root.children.insert(new_marc.get_insert_position("240"), node)
    end

    # save date and place
    if self.date || self.place
      node = MarcNode.new("publication", "260", "", "##")
      node.add_at(MarcNode.new("publication", "c", self.date, nil), 0) if self.date
      node.add_at(MarcNode.new("publication", "a", self.place, nil), 0) if self.place

      new_marc.root.children.insert(new_marc.get_insert_position("260"), node)
    end

    # save revue_title
    if self.revue_title
      node = MarcNode.new("publication", "760", "", "0#")
      node.add_at(MarcNode.new("publication", "t", self.revue_title, nil), 0)

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
    sunspot_dsl.integer :id
    sunspot_dsl.text :id_text do
      id_for_fulltext
    end

    sunspot_dsl.string :name_order do
      name
    end
    sunspot_dsl.text :short_name

    sunspot_dsl.string :author_order do
      author
    end
    sunspot_dsl.text :author

    sunspot_dsl.text :description
    sunspot_dsl.string :description_order do
      description
    end

    sunspot_dsl.text :revue_title
    sunspot_dsl.string :revue_title_order do
      revue_title
    end

    sunspot_dsl.text :volume
    sunspot_dsl.text :place
    sunspot_dsl.text :date
    sunspot_dsl.string :date_order do
      date
    end

    sunspot_dsl.text :pages

    sunspot_dsl.string :wf_stage
    sunspot_dsl.time :updated_at
    sunspot_dsl.time :created_at

    sunspot_dsl.join(:folder_id, :target => FolderItem, :type => :integer,
              :join => { :from => :item_id, :to => :id })

    sunspot_dsl.integer :src_count_order, :stored => true do
      (Publication.count_by_sql("select count(*) from sources_to_publications where publication_id = #{self[:id]}") +
      Publication.count_by_sql("select count(*) from institutions_to_publications where publication_id = #{self[:id]}") +
      Publication.count_by_sql("select count(*) from people_to_publications where publication_id = #{self[:id]}"))
    end
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
    self.description = marc.get_description
    self.author = marc.get_author
    self.revue_title = marc.get_revue_title
    self.marc_source = self.marc.to_marc
  end

  def get_record_type
    # TODO
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

  def autocomplete_label
    aut = (author and !author.empty? ? author : nil)
    des = (description and !description.empty? ? description.truncate(45) : nil)
    dat = (date and !date.empty? ? date : nil)

    infos = [aut, dat, des].join(", ")

    "#{self.short_name}: #{infos}"
  end

  def get_items
    MarcSearch.select(Publication, '760$0', id.to_s).to_a
  end

  ransacker :"240g", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"260b", proc{ |v| } do |parent| parent.table[:id] end
  ransacker :"100a_or_700a", proc{ |v| } do |parent| parent.table[:id] end

end

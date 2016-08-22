# A Place describes a physical place - like a city - where a Source is found
#
# === Fields
# * <tt>name</tt>
# * <tt>alternate_terms</tt>
# * <tt>topics</tt>
# * <tt>subtopics</tt>
# * <tt>notes</tt>
#
# Usual wf_* fields are not shown


class Latin < ActiveRecord::Base

  has_and_belongs_to_many(:referring_sources, class_name: "Source", join_table: "sources_to_latin")
  #has_many :folder_items, :as => :item
  has_many :delayed_jobs, -> { where parent_type: "Latin" }, class_name: Delayed::Job, foreign_key: "parent_id"
  belongs_to :user, :foreign_key => "wf_owner"

  validates_presence_of :name

  validates_uniqueness_of :name

  #include NewIds

  before_destroy :check_dependencies

  #before_create :generate_new_id
  after_save :reindex

  attr_accessor :suppress_reindex_trigger

  enum wf_stage: [ :inprogress, :published, :deleted ]
  enum wf_audit: [ :basic, :minimal, :full ]

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

#    string :country_order do
#      country
#    end
    text :topic

    text :notes
    text :sub_topic

#    join(:folder_id, :target => FolderItem, :type => :integer, 
#         :join => { :from => :item_id, :to => :id })

#    integer :src_count_order do 
#      src_count
#    end
  end

  def check_dependencies
    if (self.referring_sources.count > 0)
      errors.add :base, "The latin_text could not be deleted because it is used"
      return false
    end
  end

end


# A StandardTerm is a standardized title for a musical work, ex.
# Septet (from de Winter / VII Septuor)
#
# === Fields
# * <tt>title</tt> - the standardized title
# * <tt>title_d</tt> - downcase and stripped title
# * <tt>notes</tt>
# * <tt>src_count</tt> - keeps track of the Source models tied to this element
#
# Other standard wf_* not shown
# The other functions are standard, see Catalogue for a general description

class StandardTitle < ActiveRecord::Base

  has_and_belongs_to_many :sources
  has_many :folder_items, :as => :item
  belongs_to :user, :foreign_key => "wf_owner"

  validates_presence_of :title

  #include NewIds

  before_destroy :check_dependencies

  #before_create :generate_new_id
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
    string :title_order do
      title
    end
    text :title
    text :title_d

    text :notes

    join(:folder_id, :target => FolderItem, :type => :integer,
              :join => { :from => :item_id, :to => :id })

    integer :src_count_order do
      src_count
    end
  end

  def check_dependencies
    if (self.sources.count > 0)
      errors.add :base, "The standard title could not be deleted because it is used"
      return false
    end
  end

  def name
    return title
  end
end

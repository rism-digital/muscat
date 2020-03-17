# A Canonic Technique
#
# === Fields
# * <tt>canon_type</tt>
# * <tt>relation_operator</tt>
# * <tt>relation_numerator</tt> - For proportional canons: numerator
# * <tt>relation_denominator</tt> - For proportional canons: denominator
# * <tt>interval</tt> - Interval of canon
# * <tt>interval_direction</tt> - above/below
# * <tt>temporal_offset</tt> - number of offset units
# * <tt>offset_units</tt> - breves, longs, semibreves etc.
# * <tt>mensurations</tt> - This alternative font
# * <tt>src_count</tt> - keeps track of the Source models tied to this element
#
# Usual wf_* fields are not shown

class CanonicTechnique < ActiveRecord::Base

  has_and_belongs_to_many(:referring_sources, class_name: "Source", join_table: "sources_to_canonic_techniques")
  has_many :delayed_jobs, -> { where parent_type: "CanonicTechnique" }, class_name: Delayed::Job, foreign_key: "parent_id"
  belongs_to :user, :foreign_key => "wf_owner"

  validates_presence_of :canon_type

  before_destroy :check_dependencies

  after_save :reindex

  attr_accessor :suppress_reindex_trigger

  alias_attribute :id_for_fulltext, :id

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
    text :id_text do
      id_for_fulltext
    end

    text :canon_type
    text :relation_operator
    text :relation_numerator
    text :relation_denominator
    text :interval
    text :interval_direction
    text :temporal_offset
    text :offset_units
    text :mensurations

    integer :src_count_order, :stored => true do
      CanonicTechnique.count_by_sql("select count(*) from sources_to_canonic_techniques where canonic_technique_id = #{self[:id]}")
    end
  end

  def check_dependencies
    if (self.referring_sources.count > 0)
      errors.add :base, "The canonic technique could not be deleted because it is used"
      return false
    end
  end

end
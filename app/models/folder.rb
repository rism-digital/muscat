class Folder < ApplicationRecord
  include AutoStripStrings

  FOLDERABLE_TYPES = %w[
    Holding
    Institution
    InventoryItem
    LiturgicalFeast
    Person
    Place
    Publication
    Source
    StandardTerm
    StandardTitle
    User
    Work
    WorkNode
  ].freeze
  
  has_many :folder_items, :dependent => :delete_all
  has_many :delayed_jobs, -> { where parent_type: "folder" }, class_name: 'Delayed::Backend::ActiveRecord::Job', foreign_key: "parent_id"
  belongs_to :user, :foreign_key => "wf_owner"

  validates :folder_type, inclusion: { in: FOLDERABLE_TYPES }
  
  scope :for_user_and_type,   ->(user, type){ where(folder_type: type, wf_owner: user) }
  scope :for_type,   ->(type){ where(folder_type: type) }
  
  #after_destroy :remove_links
  
  before_save :update_expires

  def update_expires
    self.delete_date = 6.months.from_now
  end

  # Looks to see if an item is in the current folder.
  def has_item?(item)
    return folder_items.where(item_id: item.id, item_type: item.class.to_s).count != 0
  end

  # Get the content of the folder
  def content
    model = folder_model
    return [] unless model

    model.where(id: folder_items.pluck(:item_id))
  end

  def is_published?
    model = folder_model
    return false unless model
    return true unless model.column_names.include?("wf_stage")

    join_sql = "INNER JOIN #{model.quoted_table_name} ON #{FolderItem.quoted_table_name}.item_id = #{model.quoted_table_name}.id"

    !folder_items
      .joins(join_sql)
      .where(item_type: model.name)
      .where(model.table_name => { wf_stage: 0 })
      .exists?
  end

  def folder_model
    self.class.folder_model_for(folder_type)
  end

  def self.folder_model_for(type)
    return nil unless FOLDERABLE_TYPES.include?(type.to_s)

    type.to_s.safe_constantize
  end

  # Adds an item to the current folder. The type of the item must match the item type
  # for which this folder was created.
  def add_item(item)
    return false if item.class.name != folder_type
    return false if has_item? item
    folder_items << FolderItem.create(:folder_id => id, :item => item)
    return true
  end
  
  # Add an array of items
  # New and improved version
  # It can receive a block for feedback
  # f.add_items(all_items) {|nr| update_stage_progress("Adding item #{nr}", step: 50)}
  def add_items(items)
    items = items.to_a
    return 0 unless items.all? { |item| item.class.name == folder_type }

    items = items.uniq(&:id)
    existing_item_ids = folder_items
      .where(item_type: folder_type, item_id: items.map(&:id))
      .pluck(:item_id)
      .index_with(true)

    new_fi = []
    items.each do |item|
      next if existing_item_ids.key?(item.id)

      new_fi << FolderItem.new(folder_id: id, item: item)

      count = new_fi.length - 1
      yield count if block_given? && count % 50 == 0
    end

    FolderItem.import new_fi
    new_fi.length
  end
    
  def remove_items(items)
    items.each do |item|
      folder_item = folder_items.where(item_id: item)
      folder_items.destroy(folder_item) if folder_item
    end
    # Folder items should be always cleaned up
    # run a background job for that
    Delayed::Job.enqueue(PurgeFolderItemsJob.new(self.id))
  end  

  # https://github.com/activeadmin/activeadmin/issues/7809
  # In Non-marc models we can use the default
  def self.ransackable_associations(_) = reflections.keys
  def self.ransackable_attributes(_) = attribute_names - %w[token]

end

# Folders are used to group entries 
# and to perform batch actions on them.
class Folder < ApplicationRecord
  
  has_many :folder_items, :dependent => :delete_all
  has_many :delayed_jobs, -> { where parent_type: "folder" }, class_name: 'Delayed::Backend::ActiveRecord::Job', foreign_key: "parent_id"
  belongs_to :user, :foreign_key => "wf_owner"
  
  scope :for_user_and_type,   ->(user, type){ where(folder_type: type, wf_owner: user) }
  scope :for_type,   ->(type){ where(folder_type: type) }
  
  #after_destroy :remove_links
  	
  # Checks whether an item is in the current folder.
  # @param item
  # @return [Array]
  def has_item?(item)
    return folder_items.where(item_id: item.id, item_type: item.class.to_s).count != 0
  end

  # Get the content of the folder
  def content
    return folder_type.constantize.where(id: folder_items.pluck(:item_id))
  end

  def is_published?
    content.pluck(:wf_stage).each do |e| 
      return false if e == "inprogress"
    end
    return true
  end

  # Adds an item to the current folder. The type of the item must match the item type
  # for which this folder was created.
  # @param item
  # @return [Boolean]
  def add_item(item)
    return false if item.class.name != folder_type
    return false if has_item? item
    folder_items << FolderItem.create(:folder_id => id, :item => item)
    return true
  end
  
  # Adds an array of items
  # It uses activerecord-import and does it using a single
  # SQL IMPORT it has a dramatic improvement (on 5000 new items):
  # Using inserts   25.113613
  # Using Import    3.100459
  # @param items [Array]
  # @return [Integer]
  def add_items(items)    
    new_fi = []
    total = items.count
    count = 0 
    items.each do |item|
      return 0 if item.class.name != folder_type
      next if has_item?(item)
      new_fi << FolderItem.new(:folder_id => id, :item => item) 

      yield count if block_given? && count % 50 == 0
      count += 1
    end
  
    FolderItem.import new_fi
    return count
  end
    
  # Removes items from folder
  # @param items [Array]
  def remove_items(items)
    items.each do |item|
      folder_item = folder_items.where(item_id: item)
      folder_items.destroy(folder_item) if folder_item
    end
    # Folder items should be always cleaned up
    # make sure it is
    FolderItem.clean_index_orphans
    Sunspot.commit
  end  
    
  #def remove_links
  #  FolderItem.clean_index_orphans
  #end
end

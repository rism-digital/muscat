class Folder < ApplicationRecord
  
  has_many :folder_items, :dependent => :delete_all
  has_many :delayed_jobs, -> { where parent_type: "folder" }, class_name: 'Delayed::Backend::ActiveRecord::Job', foreign_key: "parent_id"
  belongs_to :user, :foreign_key => "wf_owner"
  
  #after_destroy :remove_links
  	
  # Looks to see if an item is in the current folder.
  def has_item?(item)
		return folder_items.where(item_id: item.id, item_type: item.class.to_s).count != 0
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
  # It uses activerecord-import and does it using a single
  # SQL IMPORT it has a dramatic improvement (on 5000 new items):
  # Using inserts   25.113613
  # Using Import    3.100459
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
    
    
  #def remove_links
  #  FolderItem.clean_index_orphans
  #end
end

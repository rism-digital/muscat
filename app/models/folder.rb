class Folder < ActiveRecord::Base
  
  has_many :folder_items, :dependent => :destroy
  
  # Looks to see if an item is in the current folder.
  def has_item?(item)
    folder_items.each { |i| return true if i == item }
    return false
  end
  
  # Adds an item to the current folder. The type of the item must match the item type
  # for which this folder was created.
  def add_item(item)
    return false if item.class.name != folder_type
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
    items.each do |item|
        return false if item.class.name != folder_type
        new_fi << FolderItem.new(:folder_id => id, :item => item)
    end
  
    FolderItem.import new_fi
    return true
  end
    
end

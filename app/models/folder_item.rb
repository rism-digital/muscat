class FolderItem < ActiveRecord::Base

  belongs_to :item, polymorphic: true
  belongs_to :folder
  
  searchable :auto_index => false do
    integer :id
    integer :folder_id
    integer :item_id
    string :item_type
  end
  
end

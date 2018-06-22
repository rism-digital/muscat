class FolderItem < ApplicationRecord

  belongs_to :item, polymorphic: true
  belongs_to :folder
  
  searchable :auto_index => false do
    integer :id
    integer :folder_id
    integer :item_id
  end
  
end

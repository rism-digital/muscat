class FolderItem < ActiveRecord::Base

  belongs_to :item, polymorphic: true
  belongs_to :folder
  
end

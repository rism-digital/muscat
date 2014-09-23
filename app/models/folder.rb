class Folder < ActiveRecord::Base
  
  has_many :sources, :through => :folder_items
  
end

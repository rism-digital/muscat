class FolderItem < ActiveRecord::Base
  
  belongs_to :source
  belongs_to :folder
  
  #searchable do
    #integer :id
    #join(:std_title, :target => Source, :type => :text, :join => { :from => :id, :to => :source_id })
    #end
  
end

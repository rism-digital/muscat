class Source < ActiveRecord::Base
  
  searchable do
      text :std_title
      text :composer
      text :source
    end
    
end

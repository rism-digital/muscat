class Work < ActiveRecord::Base
  
  belongs_to :person
  has_many :sources 
  has_many :work_incipits   
   
  before_destroy :check_dependencies

  searchable do
    integer :id
    string :title_order do
      title
    end
    text :title
    text :form
    text :notes
    
    integer :src_count_order do 
      src_count
    end
  end

  def check_dependencies
     return false if self.sources.count > 0
  end
  
end

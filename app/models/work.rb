class Work < ActiveRecord::Base
  
  belongs_to :person
  has_many :sources 
  has_many :work_incipits   
   
  before_destroy :check_dependencies

  def check_dependencies
     return false if self.sources.count > 0
  end
  
end

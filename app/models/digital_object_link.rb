class DigitalObjectLink < ActiveRecord::Base
  
    belongs_to :digital_object
    belongs_to :object_link, polymorphic: true
    belongs_to :user, :foreign_key => "wf_owner"

end

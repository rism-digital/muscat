class DigitalObjectLink < ApplicationRecord
  
    belongs_to :digital_object
    belongs_to :object_link, polymorphic: true
    belongs_to :user, :foreign_key => "wf_owner"
	
	attr_accessor :description
	
    def description
        return object_link.std_title if (object_link_type == "Source")
        return object_link.name if (object_link_type == "Person" || object_link_type == "Institution")
        "[Unspecified]"
    end
end

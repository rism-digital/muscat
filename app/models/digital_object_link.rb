class DigitalObjectLink < ApplicationRecord
  
    belongs_to :digital_object
    belongs_to :object_link, polymorphic: true
    belongs_to :user, :foreign_key => "wf_owner"
	
	attr_accessor :description
	
    def description
        return object_link.std_title if (object_link_type == "Source")
        return object_link.title if (object_link_type == "Work")
        return object_link.name if (object_link_type == "Person")
        return object_link.full_name if (object_link_type == "Institution")
        return object_link.formatted_title if (object_link_type == "Holding")
        "No description set for object type #{object_link_type}"
    end

end

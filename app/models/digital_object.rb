class DigitalObject < ApplicationRecord
  
    # attachments
    has_attached_file :attachment, 
      styles: { maximum: "900x900", medium: "300x300", thumb: "100x100>" }, 
      default_url: "/images/attachment/missing.png",
      path: "#{RISM::DIGITAL_OBJECT_PATH}/system/:class/:attachment/:id_partition/:style/:filename"
		
		validates_presence_of :description
		validates_attachment :attachment, content_type: { content_type: ["image/jpg", "image/jpeg", "image/png"] }
  
    has_many :digital_object_links, :dependent => :delete_all
    has_many :folder_items, :as => :item
    belongs_to :user, :foreign_key => "wf_owner"
    
    # fake accessor for allowing to pass additional parameters when creating an object from an object
    # the params are then used to create the digital_object_link item
    attr_accessor :new_object_link_type
    attr_accessor :new_object_link_id
end

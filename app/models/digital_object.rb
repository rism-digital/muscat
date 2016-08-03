class DigitalObject < ActiveRecord::Base
  
    # attachments
    has_attached_file :attachment, 
      styles: { maximum: "900x900", medium: "300x300", thumb: "100x100>" }, 
      default_url: "/images/attachment/missing.png",
      path: "#{RISM::DIGITAL_OBJECT_PATH}/system/:class/:attachment/:id_partition/:style/:filename"
    validates_attachment :attachment, content_type: { content_type: ["image/jpg", "image/jpeg", "image/png"] }
  
    has_many :digital_object_links
    has_many :folder_items, :as => :item
    belongs_to :user, :foreign_key => "wf_owner"

end

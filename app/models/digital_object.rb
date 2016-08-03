class DigitalObject < ActiveRecord::Base
  
    # attachments
    has_attached_file :attachment, 
      styles: { maximum: "900x900", medium: "300x300", thumb: "100x100>" }, 
      default_url: "/images/attachment/missing.png",
      path: "#{RISM::DIGITAL_OBJECT_PATH}/system/:class/:attachment/:id_partition/:style/:filename"
    validates_attachment :attachment, content_type: { content_type: ["image/jpg", "image/jpeg", "image/png"] }
  
    #belongs_to :digital_object_links
    #has_many :object_links, :through => :digital_object_links
    # acts as the the 'has_many targets' needed
    has_many :digital_object_links
    def object_links
      digital_object_links.map {|x| x.object_link}
    end
    
    
    has_many :folder_items, :as => :item
    has_many :digital_object_links, :as => :digital_object
    belongs_to :user, :foreign_key => "wf_owner"

end

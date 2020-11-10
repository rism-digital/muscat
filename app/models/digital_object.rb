class DigitalObject < ApplicationRecord
  

  Paperclip.options[:content_type_mappings] = {
    :mei => "text/xml"
  }

    # attachments
    has_attached_file :attachment, 
      styles: lambda { |a| a.instance.generate_attachment_style},
      default_url: lambda { |a| a.instance.generate_default_url},
      path: "#{RISM::DIGITAL_OBJECT_PATH}/system/:class/:attachment/:id_partition/:style/:filename"

      #styles: { maximum: "900x900", medium: "300x300", thumb: "100x100>" }, 
      #default_url: "/images/attachment/missing.png",
      #path: "#{RISM::DIGITAL_OBJECT_PATH}/system/:class/:attachment/:id_partition/:style/:filename"
		
		validates_presence_of :description
		validates_attachment :attachment, content_type: { content_type: ["image/jpg", "image/jpeg", "image/png", "text/xml", "application/xml"] }
  
    before_post_process :skip_for_mei
    after_post_process :set_metadata

    has_many :digital_object_links, :dependent => :delete_all
    has_many :folder_items, as: :item, dependent: :destroy
    belongs_to :user, :foreign_key => "wf_owner"

    enum attachment_type: [ :images, :incipit ]
    
    # fake accessor for allowing to pass additional parameters when creating an object from an object
    # the params are then used to create the digital_object_link item
    attr_accessor :new_object_link_type
    attr_accessor :new_object_link_id

    def skip_for_mei
      is_mei_type?
    end

    def set_metadata
      if is_mei_type?
        self.attachment_type = :incipit
      end
    end

    def generate_attachment_style
      if is_image_type?
        { maximum: "900x900", medium: "300x300", thumb: "100x100>" }
      else
        {}
      end
    end

    def generate_default_url
      if is_image_type?
        "/images/attachment/missing.png"
      else
        ""
      end
    end

    Paperclip.interpolates :style do |attachment, style|
      if attachment.instance.attachment_type == "incipit"
        "incipits"
      else
        style || attachment.default_style
      end
    end
    

    def is_image_type?
      attachment_content_type =~ %r(image)
    end

    def is_mei_type?
      attachment_content_type =~ %r(xml)
    end

end

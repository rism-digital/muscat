class DigitalObject < ActiveRecord::Base
  
    # atttachments
    has_attached_file :attachment, styles: { medium: "300x300>", thumb: "100x100>" }, default_url: "/images/attachment/missing.png"
    validates_attachment :attachment, content_type: { content_type: ["image/jpg", "image/jpeg", "image/png"] }
  
    belongs_to :source
    has_many :folder_items, :as => :item
    belongs_to :user, :foreign_key => "wf_owner"
end

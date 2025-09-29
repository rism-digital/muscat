class DigitalObject < ApplicationRecord
  
  include CommentsCleanup
  include AutoStripStrings

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

    enum :attachment_type, [ :images, :incipits ]
    
    before_destroy :cleanup_comments

    # fake accessor for allowing to pass additional parameters when creating an object from an object
    # the params are then used to create the digital_object_link item
    attr_accessor :new_object_link_type
    attr_accessor :new_object_link_id

    def skip_for_mei
      is_mei_type?
    end

    def set_metadata
      if is_mei_type?
        self.attachment_type = :incipits
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
      if attachment.instance.attachment_type == "incipits"
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

    # By default it is ID:pae_nr
    def match_pae_nr?(pae_nr)
      id, nr = self.description.split(':')
      return false if id == nil || nr == nil
      return nr.strip == pae_nr.strip
    end


  def self.incipits_for(model, id)
    s = model.find(id)
    incipits = {}

    s.marc.each_by_tag("031") do |t|
      subtags = [:a, :b, :c, :t]
      vals = {}

      subtags.each do |st|
        v = t.fetch_first_by_tag(st)
        vals[st] = v && v.content ? v.content : "x"
      end

      pae_nr = "#{vals[:a]}.#{vals[:b]}.#{vals[:c]}"
      text = vals[:t] == "x" ? "" : " #{vals[:t]}"
      incipits["#{pae_nr}#{text}"] = "#{s.id}:#{pae_nr}"
    end
    incipits
  end

  # https://github.com/activeadmin/activeadmin/issues/7809
  # In Non-marc models we can use the default
  # If we define our own ransacker, we need this
  def self.ransackable_attributes(auth_object = nil)
    column_names + _ransackers.keys
  end

  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s }
  end

  def display_name
    self.description
  end

end

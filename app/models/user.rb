class User < ActiveRecord::Base

  has_and_belongs_to_many :workgroups
  attr_accessible :email, :password, :preference_wf_stage, :password_confirmation if Rails::VERSION::MAJOR < 4
  has_many :sources, foreign_key: 'wf_owner'
# Connects this user object to Blacklights Bookmarks. 
  include Blacklight::User
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable

  enum preference_wf_stage: [ :inprogress, :published, :deleted ]
  scope :ordered, -> {
    joins(:workgroups).order("workgroup.name")
          
  }
  
  searchable :auto_index => false do
    integer :id
    text :name
  end


  def can_edit?(source)
    if source.child_sources.count > 0
      libs=[]
      source.child_sources.each do |so| 
        so.institutions.each do |l|
          libs<<l
        end
      end
      (libs & (self.workgroups.map {|ins| ins.get_institutions}).flatten).any?
    else
      (source.institutions & (self.workgroups.map {|ins| ins.get_institutions}).flatten).any?
    end
  end

  def can_create_edition?(source)
    if (source.record_type == MarcSource::RECORD_TYPES[:edition] ||
      source.record_type == MarcSource::RECORD_TYPES[:edition_content] ||
      source.record_type == MarcSource::RECORD_TYPES[:libretto_edition_content] ||
      source.record_type == MarcSource::RECORD_TYPES[:theoretica_edition_content])
     if can? :create_edition?, source
       true
     else
       false
     end
   end
   true
  end

  def get_workgroups
    self.workgroups.map {|ins| ins.name}
  end
  
  def workgroup
    get_workgroups.join(", ")
  end

  def get_roles
    self.roles.map {|r| r.name}
  end

  def online?
      updated_at > 10.minutes.ago
  end
 
  def active?
    return false unless last_sign_in_at
    last_sign_in_at > (DateTime.now - 4.weeks) ? true : false
  end
end

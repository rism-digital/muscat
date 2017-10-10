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
  
  #515 postponed to 3.7
  #validate :secure_password
  
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
    last_sign_in_at > (DateTime.now - 12.weeks) ? true : false
  end

  def restricted?(model)
    roles.select {|r| r.name =~ /restricted/}.each do |role|
      restricted_model = role.name.split("_")[0]
      if model != restricted_model
        next
      else
        return true
      end
    end
    return false
  end

  # returns a list of users sorted by lastname with admin at first place; utf-8 chars included
  def self.sort_all_by_last_name
    res = {}
    User.all.each do |u|
      res[u.id] = [I18n.transliterate(u.name.sub("Admin", "00admin").split(" ").last).downcase, u]
    end
    return res.sort_by{|_key, value| value.first}.map {|e| e[1][1] }
  end

=begin #515 postponed to 3.7
  def secure_password
    return true if !password
    if (password.length < 8)
      errors.add :password, "the password must to be at least 8 characters long"
      return false
    end
    if (password =~ /[a-z]/).blank?
      errors.add :password, "the password must to contain at least one lower case letter"
      return false
    end
    if (password =~ /[A-Z]/).blank?
      errors.add :password, "the password must to contain at least one upper case letter"
      return false
    end
    if (password =~ /[0-9]/).blank?
      errors.add :password, "the password must to contain at least one number"
      return false
    end
    return true
	end
=end

end

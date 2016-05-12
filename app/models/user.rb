class User < ActiveRecord::Base

  has_and_belongs_to_many :workgroups
  attr_accessible :email, :password, :password_confirmation if Rails::VERSION::MAJOR < 4
# Connects this user object to Blacklights Bookmarks. 
  include Blacklight::User
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable

  def can_edit?(source)
    if sourcechild_sources.count > 0
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

  def get_workgroups
    self.workgroups.map {|ins| ins.name}
  end
  
  def get_roles
    self.roles.map {|r| r.name}
  end

  def online?
      updated_at > 10.minutes.ago
  end
  
end

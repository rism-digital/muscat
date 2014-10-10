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
    if source.respond_to? :sources
      libs=[]
      source.sources.each do |so| 
        so.libraries.each do |l|
          libs<<l
        end
      end
      (libs & (self.workgroups.map {|ins| ins.get_libraries}).flatten).any?
    else
      (source.libraries & (self.workgroups.map {|ins| ins.get_libraries}).flatten).any?
    end
  end

  def get_workgroups
    self.workgroups.map {|ins| ins.name}
  end
end

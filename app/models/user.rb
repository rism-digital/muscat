class User < ActiveRecord::Base

  has_and_belongs_to_many :institutions
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
    (source.libraries & (self.workgroups.map {|ins| ins.get_libraries}).flatten).any?
  end

  def get_workgroups
    self.workgroups.map {|ins| ins.name}
  end
end

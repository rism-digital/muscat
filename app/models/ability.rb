class Ability
  include CanCan::Ability

  def initialize(user)
    if user.has_role? :admin
      can :manage, :all
    elsif user.has_role? :guest
      can :read, :all
    end
    #can :read, User
    #can :manage, User, :id => user.id
    #can :read, ActiveAdmin::Page, :name => "Dashboard"
  end

end

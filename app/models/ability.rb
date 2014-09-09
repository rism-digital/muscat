class Ability
  include CanCan::Ability

  def initialize(user)
    if user.has_role? :admin
      can :manage, :all
    elsif user.has_role? :guest
      can :read, :all
      can :read, ActiveAdmin::Page, :name => "Dashboard"
    elsif user.has_role?(:editor, Person)
      can :read, Person
      can :read, Source
      can :update, Source do |source|
        user.can_edit? source
       end
      can :read, ActiveAdmin::Page, :name => "Dashboard"
      #cannot :read, User
    end
    #can :read, User
    #can :manage, User, :id => user.id
    #can :read, ActiveAdmin::Page, :name => "Dashboard"
  end

end

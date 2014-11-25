class Ability
  include CanCan::Ability

  def initialize(user)
    if user.has_role? :admin
      can :manage, :all
    elsif user.has_role? :guest
      can :read, :all
      can :read, ActiveAdmin::Page, :name => "Dashboard"
    elsif user.has_role?(:editor, Person)
      can :manage, Person
      can :manage, Source
      can [:read, :create], ActiveAdmin::Comment
      can :read, ActiveAdmin::Page, :name => "Dashboard"
      #cannot :read, User
    elsif user.has_role?(:cataloger, Person)
      can [:read, :create], Person
      can :read, Source
      can [:read, :create], ActiveAdmin::Comment
      can :update, Source do |source|
        user.can_edit? source
       end
      can :read, ActiveAdmin::Page, :name => "Dashboard"
    end
  end

end

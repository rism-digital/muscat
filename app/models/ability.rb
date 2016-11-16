# FIXME for next revision: implment inheritance
class Ability
  include CanCan::Ability

  def initialize(user)

    if user.has_role? :admin
      can :manage, :all
      can :reindex, [Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Folder]
      can :publish, [Folder]
      can :create_editions, Source
      can :update_editions, Source
      
      can :resave, :all

    elsif user.has_role? :guest
      can [:read, :create], ActiveAdmin::Comment
      can :read, :all
      can :read, ActiveAdmin::Page, :name => "Dashboard"
      can :read, User, :id => user.id

    elsif user.has_role?(:editor)
      can [:read, :create, :update, :destroy], [DigitalObject, DigitalObjectLink, Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Source, Work, Holding]
      
      can :create_editions, Source
      can :update_editions, Source
      
      can :manage, Folder, :wf_owner => user.id
      can [:read, :create, :destroy], ActiveAdmin::Comment
      can :read, ActiveAdmin::Page, :name => "Dashboard"
      can :read, ActiveAdmin::Page, :name => "guidelines"
      can :read, ActiveAdmin::Page, :name => "doc"
      can [:read], User, :id => user.id

    elsif user.has_role?(:cataloger)
      # A cataloguer can create new items but modify only the ones ho made
      can [:read, :create], [Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Work, Holding]
      can :update, [Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Work, Holding], :wf_owner => user.id
      can :create, DigitalObject
      can [:destroy, :read, :update], DigitalObject, :wf_owner => user.id
      can [:read, :update], DigitalObjectLink
      can [:destroy], DigitalObjectLink do |link|
        link.object_link.wf_owner == user.id
      end
      
      can [:manage], Folder, :wf_owner => user.id
      can [:read, :create, :update], ActiveAdmin::Comment
      
      can [:read, :create], Source
      can :update, Source, :wf_owner => user.id
      can :update, Source do |source|
        user.can_edit? source
      end
      
      cannot :create_editions, Source
      cannot :update_editions, Source
      
      can :read, ActiveAdmin::Page, :name => "Dashboard"
      can :read, ActiveAdmin::Page, :name => "guidelines"
      can :read, ActiveAdmin::Page, :name => "doc"
      can [:read], User, :id => user.id
    elsif user.has_role?(:cataloger_prints)
      # A cataloguer can create new items but modify only the ones ho made
      can [:read, :create], [Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Work, Holding]
      can :update, [Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Work, Holding], :wf_owner => user.id
      can :create, DigitalObject
      can [:destroy, :read, :update], DigitalObject, :wf_owner => user.id
      can [:destroy, :read, :update], DigitalObjectLink
      
      can [:manage], Folder, :wf_owner => user.id
      can [:read, :create, :update], ActiveAdmin::Comment
      
      can [:read, :create], Source
      can :update, Source, :wf_owner => user.id
      can :update, Source do |source|
        user.can_edit? source
      end
      
      # THE DIFFERENCE WITH CATALOGUER
      can :create_editions, Source
      can :update_editions, Source
      
      can :read, ActiveAdmin::Page, :name => "Dashboard"
      can :read, ActiveAdmin::Page, :name => "guidelines"
      can :read, ActiveAdmin::Page, :name => "doc"
      can [:read], User, :id => user.id
    end

  end
  
end

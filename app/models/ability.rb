# FIXME for next revision: implment inheritance
class Ability
  include CanCan::Ability

  def initialize(user)
    
    #########
    # Admin #
    #########

    if user.has_role?(:admin)
      can :manage, :all
      can :reindex, [Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Folder]
      can :publish, [Folder]
      can :upublish, [Folder]
      can :create_editions, Source
      can :update_editions, Source      
      can :resave, :all

    ##########
    # Editor #
    ##########

    elsif user.has_role?(:editor)
      if user.has_role?(:person_editor)
        can [:read, :create, :update, :destroy], [DigitalObject, DigitalObjectLink, Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Source, Work, Holding]
      else
        can [:read, :create, :update, :destroy], [DigitalObject, DigitalObjectLink, Catalogue, Institution, LiturgicalFeast, Place, StandardTerm, StandardTitle, Source, Work, Holding]
        can [:read, :create], Person
        can :update, Person, :wf_owner => user.id
      end
      can :create_editions, Source
      can :update_editions, Source
      can :manage, Folder, :wf_owner => user.id
      can :upublish, [Folder]
      can [:read, :create, :destroy], ActiveAdmin::Comment
      can :read, ActiveAdmin::Page, :name => "Dashboard"
      can :read, ActiveAdmin::Page, :name => "guidelines"
      can :read, ActiveAdmin::Page, :name => "doc"
      can :read, ActiveAdmin::Page, :name => "Statistics"
      #515 postponed to 3.7, add :update
      can [:read], User, :id => user.id
    
    ##############
    # Cataloguer #
    ##############

    elsif user.has_role?(:cataloger) || user.has_role?(:cataloger_prints)
      # A cataloguer can create new items but modify only the ones ho made
      can [:read, :create], [Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Work, Holding]
      if user.has_role?(:person_restricted)
        # catalogers can get restriced access to the persons form
        # the general design of the role allows extensions alike for e.g. institudions
        can :update, Person
      end
      can :update, [Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Work, Holding], :wf_owner => user.id
      can [:destroy, :update], [DigitalObject, Holding], :wf_owner => user.id
      can [:read, :create, :add_item, :remove_item], DigitalObject
      can [:read, :update, :create], DigitalObjectLink
      can [:destroy], DigitalObjectLink do |link|
        # the owner of the link is always set to the owner of the object it points to,
        # so only the first condition will happen. We could change this eventually
        (link.object_link.wf_owner == user.id) or (link.wf_owner == user.id)
      end
      can [:manage], Folder, :wf_owner => user.id
      can [:read, :create], ActiveAdmin::Comment
      can [:destroy, :update], ActiveAdmin::Comment, :author_id => user.id
      can [:read, :create], Source
      can :update, Source, :wf_owner => user.id
      can :update, Source do |source|
        user.can_edit? source
      end
      
      # The difference between withouth or with print rights
      if user.has_role?(:cataloger)
        cannot :create_editions, Source
        cannot :update_editions, Source
      else
        can :create_editions, Source
        can :update_editions, Source
      end
      
      can :read, ActiveAdmin::Page, :name => "Dashboard"
      can :read, ActiveAdmin::Page, :name => "guidelines"
      can :read, ActiveAdmin::Page, :name => "doc"
      can [:read], User, :id => user.id
    
    #########
    # Guest #
    #########

    elsif user.has_role? :guest
      can [:read, :create], ActiveAdmin::Comment
      can :read, :all
      can :read, ActiveAdmin::Page, :name => "Dashboard"
      can :read, User, :id => user.id
    
    
    end
    
    

  end
  
end

# Specifies the Abilities of the User-Roles
# @todo FIXME for next revision: implment inheritance
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
      can :unpublish, [Folder]
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
      can [:read], Folder
      can :manage, Folder, :wf_owner => user.id
      can :unpublish, [Folder]
      can [:read, :create, :destroy], ActiveAdmin::Comment
      can :read, ActiveAdmin::Page, :name => "Dashboard"
      can :read, ActiveAdmin::Page, :name => "guidelines"
      can :read, ActiveAdmin::Page, :name => "doc"
      can :read, ActiveAdmin::Page, :name => "Statistics"

      #515 postponed to 3.7, add :update
      # NOTE password is in :manage
      can [:read, :update], User, :id => user.id
    
    ##############
    # Cataloguer #
    ##############

    elsif user.has_role?(:cataloger)
      # A cataloguer can create new items but modify only the ones ho made
      can [:read, :create], [Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Work, Holding]
      if user.has_role?(:person_restricted)
        # catalogers can get restriced access to the persons form
        # the general design of the role allows extensions alike for e.g. institudions
        can :update, Person
      end
      can :update, [Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Holding, Work], :wf_owner => user.id
      can [:destroy, :update], [DigitalObject], :wf_owner => user.id
      can [:destroy], [Holding], :wf_owner => user.id
      can [:update], [Holding] do |holding|
        user.can_edit?(holding)
      end
      can [:read, :create, :add_item, :remove_item], DigitalObject
      can [:read, :update, :create], DigitalObjectLink
      can [:destroy], DigitalObjectLink do |link|
        # the owner of the link is always set to the owner of the object it points to,
        # so only the first condition will happen. We could change this eventually
        (link.object_link.wf_owner == user.id) or (link.wf_owner == user.id)
      end
      can [:read], Folder
      can [:manage], Folder, :wf_owner => user.id
      can [:publish], Folder do |folder|
        user.can_publish?(folder)
      end
      cannot [:unpublish, :reindex], Folder
      can [:read, :create, :destroy], ActiveAdmin::Comment
      can [:update], ActiveAdmin::Comment, :author_id => user.id
      can [:read, :create], Source
      can :update, Source, :wf_owner => user.id
      can :update, Source do |source|
        user.can_edit? source
      end
      
      can :update, Source do |s|
        user.can_edit_edition?(s)
      end

      can :read, ActiveAdmin::Page, :name => "Dashboard"
      can :read, ActiveAdmin::Page, :name => "guidelines"
      can :read, ActiveAdmin::Page, :name => "doc"
      can [:read, :update], User, :id => user.id
    
    #########
    # Guest #
    #########

    elsif user.has_role? :guest
      can [:read, :create], ActiveAdmin::Comment
      can :read, :all
      can :read, ActiveAdmin::Page, :name => "Dashboard"
      can :read, User, :id => user.id
      cannot :read, ActiveAdmin::Page, :name => "Statistics"
      cannot :read, Workgroup
    end
  end
end

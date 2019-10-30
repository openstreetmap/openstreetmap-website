# frozen_string_literal: true

class ApiAbility
  include CanCan::Ability

  def initialize(user)
    can :show, :capability
    can :index, :change
    can :index, :map
    can :show, :permission
    can :show, :version

    if Settings.status != "database_offline"
      can [:show, :download, :query], Changeset
      can [:index, :create, :comment, :feed, :show, :search], Note
      can :index, Tracepoint
      can [:index, :show], User
      can [:index, :show], Node
      can [:index, :show, :full, :ways_for_node], Way
      can [:index, :show, :full, :relations_for_node, :relations_for_way, :relations_for_relation], Relation
      can [:history, :version], OldNode
      can [:history, :version], OldWay
      can [:history, :version], OldRelation
    end

    if user
      can :welcome, :site
      can [:revoke, :authorize], :oauth

      if Settings.status != "database_offline"
        can [:index, :new, :create, :show, :edit, :update, :destroy], ClientApplication
        can [:new, :create, :reply, :show, :inbox, :outbox, :mark, :destroy], Message
        can [:close, :reopen], Note
        can [:new, :create], Report
        can [:create, :show, :update, :destroy, :data], Trace
        can [:details, :gpx_files], User
        can [:read, :read_one, :update, :update_one, :delete_one], UserPreference

        if user.terms_agreed?
          can [:create, :update, :upload, :close, :subscribe, :unsubscribe, :expand_bbox], Changeset
          can :create, ChangesetComment
          can [:create, :update, :delete], Node
          can [:create, :update, :delete], Way
          can [:create, :update, :delete], Relation
        end

        if user.moderator?
          can [:destroy, :restore], ChangesetComment
          can :destroy, Note

          if user.terms_agreed?
            can :redact, OldNode
            can :redact, OldWay
            can :redact, OldRelation
          end
        end
      end
    end

    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  end
end

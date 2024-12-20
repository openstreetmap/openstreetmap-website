# frozen_string_literal: true

class ApiAbility
  include CanCan::Ability

  def initialize(user)
    can :read, [:version, :capability, :permission, :map]

    if Settings.status != "database_offline"
      can [:read, :download], Changeset
      can [:read, :create, :feed, :search], Note
      can :read, Tracepoint
      can :read, User
      can :read, Node
      can [:read, :full, :ways_for_node], Way
      can [:read, :full, :relations_for_node, :relations_for_way, :relations_for_relation], Relation
      can [:history, :read], [OldNode, OldWay, OldRelation]
      can :read, UserBlock

      if user&.active?
        can [:comment, :close, :reopen], Note
        can [:read, :create, :update, :destroy], Trace
        can [:details, :gpx_files], User
        can [:read, :update, :update_all, :destroy], UserPreference

        if user.terms_agreed?
          can [:create, :update, :upload, :close, :subscribe, :unsubscribe], Changeset
          can :create, ChangesetComment
          can [:create, :update, :delete], [Node, Way, Relation]
        end

        if user.moderator?
          can [:destroy, :restore], ChangesetComment
          can :destroy, Note

          can :redact, [OldNode, OldWay, OldRelation] if user.terms_agreed?
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

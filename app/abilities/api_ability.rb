# frozen_string_literal: true

class ApiAbility
  include CanCan::Ability

  def initialize(token)
    can :read, [:version, :capability, :permission, :map]

    if Settings.status != "database_offline"
      user = User.find(token.resource_owner_id) if token

      can [:read, :feed, :search], Note
      can :create, Note unless token

      can [:read, :download], Changeset
      can :read, Tracepoint
      can :read, User
      can :read, Node
      can [:read, :full, :ways_for_node], Way
      can [:read, :full, :relations_for_node, :relations_for_way, :relations_for_relation], Relation
      can [:history, :read], [OldNode, OldWay, OldRelation]
      can :read, UserBlock

      if user&.active?
        can [:create, :comment, :close, :reopen], Note if scope?(token, :write_notes)
        can [:create, :destroy], NoteSubscription if scope?(token, :write_notes)

        can :read, Trace if scope?(token, :read_gpx)
        can [:create, :update, :destroy], Trace if scope?(token, :write_gpx)

        can :details, User if scope?(token, :read_prefs)
        can :read, UserPreference if scope?(token, :read_prefs)
        can [:update, :update_all, :destroy], UserPreference if scope?(token, :write_prefs)

        can [:read, :update, :destroy], Message if scope?(token, :consume_messages)
        can :create, Message if scope?(token, :send_messages)

        if user.terms_agreed?
          can [:create, :update, :upload, :close, :subscribe, :unsubscribe], Changeset if scope?(token, :write_api)
          can :create, ChangesetComment if scope?(token, :write_api)
          can [:create, :update, :delete], [Node, Way, Relation] if scope?(token, :write_api)
        end

        if user.moderator?
          can [:destroy, :restore], ChangesetComment if scope?(token, :write_api)

          can :destroy, Note if scope?(token, :write_notes)

          can :redact, [OldNode, OldWay, OldRelation] if user&.terms_agreed? && scope?(token, :write_redactions)
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

  private

  def scope?(token, scope)
    token&.includes_scope?(scope)
  end
end

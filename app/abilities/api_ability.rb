# frozen_string_literal: true

class ApiAbility
  include CanCan::Ability

  def initialize(user, scopes) # rubocop:disable Metrics/CyclomaticComplexity
    can :read, [:version, :capability, :permission, :map]

    if Settings.status != "database_offline"
      can [:read, :feed, :search], Note
      can :create, Note unless user

      can :read, Changeset
      can :read, ChangesetComment
      can :read, Tracepoint
      can :read, User
      can :read, [Node, Way, Relation, OldNode, OldWay, OldRelation]
      can :read, UserBlock

      if user&.active?
        can [:create, :comment, :close, :reopen], Note if scopes.include?("write_notes")
        can [:create, :destroy], NoteSubscription if scopes.include?("write_notes")

        can :read, Trace if scopes.include?("read_gpx")
        can [:create, :update, :destroy], Trace if scopes.include?("write_gpx")

        can :details, User if scopes.include?("read_prefs")
        can :read, UserPreference if scopes.include?("read_prefs")
        can [:update, :update_all, :destroy], UserPreference if scopes.include?("write_prefs")

        can [:read, :update, :destroy], Message if scopes.include?("consume_messages")
        can :create, Message if scopes.include?("send_messages")

        can :read, :active_user_blocks_list if scopes.include?("read_prefs")

        if user.terms_agreed?
          can [:create, :update, :upload, :close], Changeset if scopes.include?("write_map")
          can [:create, :destroy], ChangesetSubscription if scopes.include?("write_map")
          can :create, ChangesetComment if scopes.include?("write_changeset_comments")
          can [:create, :update, :destroy], [Node, Way, Relation] if scopes.include?("write_map")
        end

        if user.moderator?
          can [:create, :destroy], :changeset_comment_visibility if scopes.include?("write_changeset_comments")

          can :destroy, Note if scopes.include?("write_notes")

          can [:create, :destroy], :element_version_redaction if user.terms_agreed? && scopes.include?("write_redactions")

          can :create, UserBlock if scopes.include?("write_blocks")
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

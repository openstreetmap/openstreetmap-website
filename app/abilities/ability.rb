# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can :read, [:feature_query, :map_key]
    can :read, [Node, Way, Relation, OldNode, OldWay, OldRelation]
    can [:show, :create], Note
    can :search, :direction
    can [:index, :permalink, :edit, :help, :fixthemap, :offline, :export, :about, :communities, :preview, :copyright, :id], :site
    can [:finish, :embed], :export
    can [:search, :search_latlon, :search_osm_nominatim, :search_osm_nominatim_reverse], :geocoder

    if Settings.status != "database_offline"
      can [:read, :feed], Changeset
      can :read, ChangesetComment
      can [:confirm, :confirm_resend, :confirm_email], :confirmation
      can [:read, :rss], DiaryEntry
      can :read, DiaryComment
      can [:index], Note
      can [:create, :update], :password
      can :read, Redaction
      can [:create, :destroy], :session
      can [:read, :data], Trace
      can [:read, :create, :suspended, :auth_success, :auth_failure], User
      can :read, UserBlock
    end

    if user&.active?
      can :welcome, :site
      can :read, [:deletion, :account_terms, :account_pd_declaration, :account_home]

      if Settings.status != "database_offline"
        can [:read, :create, :destroy], ChangesetSubscription
        can [:read, :create, :update, :destroy], :oauth2_application
        can [:read, :destroy], :oauth2_authorized_application
        can [:read, :create, :destroy], :oauth2_authorization
        can [:read, :update, :destroy], :account
        can :update, :account_terms
        can :create, :account_pd_declaration
        can :read, :dashboard
        can [:create, :subscribe, :unsubscribe], DiaryEntry
        can :update, DiaryEntry, :user => user
        can [:create], DiaryComment
        can [:show, :create, :destroy], Follow
        can [:read, :create, :destroy], Message
        can [:close, :reopen], Note
        can [:read, :update], :preference
        can :update, :profile
        can :create, Report
        can [:mine, :create, :update, :destroy], Trace
        can [:account, :go_public], User
        can [:read, :create, :destroy], UserMute

        if user.moderator?
          can [:hide, :unhide], [DiaryEntry, DiaryComment]
          can [:read, :resolve, :ignore, :reopen], Issue
          can :create, IssueComment
          can [:create, :update, :destroy], Redaction
          can [:create, :destroy], UserBlock
          can :update, UserBlock, :creator => user
          can :update, UserBlock, :revoker => user
          can :update, UserBlock, :active? => true
        end

        if user.administrator?
          can [:hide, :unhide], [DiaryEntry, DiaryComment]
          can [:read, :resolve, :ignore, :reopen], Issue
          can :create, IssueComment

          can [:update], :user_status
          can [:read, :update], :users_list
          can [:create, :destroy], UserRole
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

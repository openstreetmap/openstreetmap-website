# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can :query, :browse
    can :show, [Node, Way, Relation]
    can [:index, :show], [OldNode, OldWay, OldRelation]
    can [:show, :create], Note
    can :search, :direction
    can [:index, :permalink, :edit, :help, :fixthemap, :offline, :export, :about, :communities, :preview, :copyright, :key, :id], :site
    can [:finish, :embed], :export
    can [:search, :search_latlon, :search_osm_nominatim, :search_osm_nominatim_reverse], :geocoder

    if Settings.status != "database_offline"
      can [:index, :feed, :show], Changeset
      can :show, ChangesetComment
      can [:confirm, :confirm_resend, :confirm_email], :confirmation
      can [:index, :rss, :show], DiaryEntry
      can :index, DiaryComment
      can [:index], Note
      can [:create, :update], :password
      can [:index, :show], Redaction
      can [:create, :destroy], :session
      can [:index, :show, :data, :georss], Trace
      can [:terms, :create, :save, :suspended, :show, :auth_success, :auth_failure], User
      can [:index, :show, :blocks_on, :blocks_by], UserBlock
    end

    if user&.active?
      can :welcome, :site
      can [:show], :deletion

      if Settings.status != "database_offline"
        can [:subscribe, :unsubscribe], Changeset
        can [:index, :create, :show, :update, :destroy], :oauth2_application
        can [:index, :destroy], :oauth2_authorized_application
        can [:show, :create, :destroy], :oauth2_authorization
        can [:update, :destroy], :account
        can [:show], :dashboard
        can [:create, :subscribe, :unsubscribe], DiaryEntry
        can :update, DiaryEntry, :user => user
        can [:create], DiaryComment
        can [:make_friend, :remove_friend], Friendship
        can [:create, :reply, :show, :inbox, :outbox, :muted, :mark, :unmute, :destroy], Message
        can [:close, :reopen], Note
        can [:show, :update], :preference
        can :update, :profile
        can :create, Report
        can [:mine, :create, :update, :destroy], Trace
        can [:account, :go_public], User
        can [:index, :create, :destroy], UserMute

        if user.moderator?
          can [:hide, :unhide], [DiaryEntry, DiaryComment]
          can [:index, :show, :resolve, :ignore, :reopen], Issue
          can :create, IssueComment
          can [:create, :update, :destroy], Redaction
          can [:create, :revoke_all], UserBlock
          can :update, UserBlock, :creator => user
          can :update, UserBlock, :revoker => user
          can :update, UserBlock, :active? => true
        end

        if user.administrator?
          can [:hide, :unhide], [DiaryEntry, DiaryComment]
          can [:index, :show, :resolve, :ignore, :reopen], Issue
          can :create, IssueComment
          can [:set_status, :destroy, :index], User
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

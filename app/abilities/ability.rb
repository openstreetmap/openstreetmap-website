# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can :show, :query
    can :show, [Node, Way, Relation]
    can [:index, :show], [OldNode, OldWay, OldRelation]
    can [:show, :new], Note
    can :search, :direction
    can [:index, :permalink, :edit, :help, :fixthemap, :offline, :export, :about, :communities, :preview, :copyright, :key, :id], :site
    can [:finish, :embed], :export
    can [:search, :search_latlon, :search_osm_nominatim, :search_osm_nominatim_reverse], :geocoder
    can [:token, :request_token, :access_token, :test_request], :oauth

    if Settings.status != "database_offline"
      can [:index, :feed, :show], Changeset
      can :index, ChangesetComment
      can [:confirm, :confirm_resend, :confirm_email], :confirmation
      can [:index, :rss, :show, :comments], DiaryEntry
      can [:index], Note
      can [:new, :create, :edit, :update], :password
      can [:index, :show], Redaction
      can [:new, :create, :destroy], :session
      can [:index, :show, :data, :georss, :picture, :icon], Trace
      can [:terms, :new, :create, :save, :suspended, :show, :auth_success, :auth_failure], User
      can [:index, :show, :blocks_on, :blocks_by], UserBlock
    end

    if user&.active?
      can :welcome, :site
      can [:revoke, :authorize], :oauth
      can [:show], :deletion

      if Settings.status != "database_offline"
        can [:subscribe, :unsubscribe], Changeset
        can [:index, :new, :create, :show, :edit, :update, :destroy], ClientApplication
        can [:index, :new, :create, :show, :edit, :update, :destroy], :oauth2_application
        can [:index, :destroy], :oauth2_authorized_application
        can [:new, :show, :create, :destroy], :oauth2_authorization
        can [:edit, :update, :destroy], :account
        can [:show], :dashboard
        can [:new, :create, :edit, :update, :comment, :subscribe, :unsubscribe], DiaryEntry
        can [:make_friend, :remove_friend], Friendship
        can [:new, :create, :reply, :show, :inbox, :outbox, :muted, :mark, :unmute, :destroy], Message
        can [:close, :reopen], Note
        can [:show, :edit, :update], :preference
        can [:edit, :update], :profile
        can [:new, :create], Report
        can [:mine, :new, :create, :edit, :update, :destroy], Trace
        can [:account, :go_public], User
        can [:index, :create, :destroy], UserMute

        if user.moderator?
          can [:hide, :unhide, :hidecomment, :unhidecomment], DiaryEntry
          can [:index, :show, :resolve, :ignore, :reopen], Issue
          can :create, IssueComment
          can [:new, :create, :edit, :update, :destroy], Redaction
          can [:new, :edit, :create, :update, :revoke, :revoke_all], UserBlock
        end

        if user.administrator?
          can [:hide, :unhide, :hidecomment, :unhidecomment], DiaryEntry
          can [:index, :show, :resolve, :ignore, :reopen], Issue
          can :create, IssueComment
          can [:set_status, :destroy, :index], User
          can [:grant, :revoke], UserRole
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

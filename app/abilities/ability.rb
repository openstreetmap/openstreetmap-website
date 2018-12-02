# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can :index, ChangesetComment
    can [:index, :permalink, :edit, :help, :fixthemap, :offline, :export, :about, :preview, :copyright, :key, :id], :site
    can [:index, :rss, :show, :comments], DiaryEntry
    can [:search, :search_latlon, :search_ca_postcode, :search_osm_nominatim,
         :search_geonames, :search_osm_nominatim_reverse, :search_geonames_reverse], :geocoder
    can [:index, :create, :comment, :feed, :show, :search, :mine], Note
    can [:index, :show], Redaction
    can [:index, :show, :blocks_on, :blocks_by], UserBlock

    if user
      can :welcome, :site
      can :create, ChangesetComment
      can [:create, :edit, :comment, :subscribe, :unsubscribe], DiaryEntry
      can [:close, :reopen], Note
      can [:new, :create], Report
      can [:read, :read_one, :update, :update_one, :delete_one], UserPreference

      if user.moderator?
        can [:destroy, :restore], ChangesetComment
        can [:index, :show, :resolve, :ignore, :reopen], Issue
        can :create, IssueComment
        can :destroy, Note
        can [:new, :create, :edit, :update, :destroy], Redaction
        can [:new, :edit, :create, :update, :revoke], UserBlock
      end

      if user.administrator?
        can [:hide, :hidecomment], [DiaryEntry, DiaryComment]
        can [:index, :show, :resolve, :ignore, :reopen], Issue
        can :create, IssueComment
        can [:grant, :revoke], UserRole
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

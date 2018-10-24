# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can [:index, :permalink, :edit, :help, :fixthemap, :offline, :export, :about, :preview, :copyright, :key, :id], :site
    can [:index, :rss, :show, :comments], DiaryEntry
    can [:search, :search_latlon, :search_ca_postcode, :search_osm_nominatim,
         :search_geonames, :search_osm_nominatim_reverse, :search_geonames_reverse], :geocoder

    if user
      can :welcome, :site
      can [:create, :edit, :comment, :subscribe, :unsubscribe], DiaryEntry
      can [:new, :create], Report
      can [:read, :read_one, :update, :update_one, :delete_one], UserPreference

      if user.moderator?
        can [:index, :show, :resolve, :ignore, :reopen], Issue
        can :create, IssueComment
      end

      if user.administrator?
        can [:hide, :hidecomment], [DiaryEntry, DiaryComment]
        can [:index, :show, :resolve, :ignore, :reopen], Issue
        can :create, IssueComment
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

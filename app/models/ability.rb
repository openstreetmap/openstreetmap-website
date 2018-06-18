# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can :index, :site
    can [:permalink, :edit, :help, :fixthemap, :offline, :export, :about, :preview, :copyright, :key, :id, :welcome], :site

    can [:list, :rss, :view, :comments], DiaryEntry

    can [:search, :search_latlon, :search_ca_postcode, :search_osm_nominatim,
         :search_geonames, :search_osm_nominatim_reverse, :search_geonames_reverse], :geocoder

    if user
      can :weclome, :site

      can [:create, :edit, :comment, :subscribe, :unsubscribe], DiaryEntry

      can [:hide, :hidecomment], [DiaryEntry, DiaryComment] if user.administrator?
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

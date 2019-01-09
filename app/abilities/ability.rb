# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can [:relation, :relation_history, :way, :way_history, :node, :node_history, :changeset, :note, :new_note], :browse
    can [:index, :feed, :read, :download, :query], Changeset
    can :index, ChangesetComment
    can :search, :direction
    can [:index, :permalink, :edit, :help, :fixthemap, :offline, :export, :about, :preview, :copyright, :key, :id], :site
    can [:index, :rss, :show, :comments], DiaryEntry
    can [:finish, :embed], :export
    can [:search, :search_latlon, :search_ca_postcode, :search_osm_nominatim,
         :search_geonames, :search_osm_nominatim_reverse, :search_geonames_reverse], :geocoder
    can [:index, :create, :comment, :feed, :show, :search, :mine], Note
    can [:index, :show], Redaction
    can [:search_all, :search_nodes, :search_ways, :search_relations], :search
    can [:trackpoints], :swf
    can [:index, :show, :data, :georss, :picture, :icon], Trace
    can [:terms, :api_users, :login, :logout, :new, :create, :save, :confirm, :confirm_resend, :confirm_email, :lost_password, :reset_password, :show, :api_read, :auth_success, :auth_failure], User
    can [:index, :show, :blocks_on, :blocks_by], UserBlock

    if user
      can :welcome, :site
      can [:index, :new, :create, :show, :edit, :update, :destroy], ClientApplication
      can [:create, :edit, :comment, :subscribe, :unsubscribe], DiaryEntry
      can [:new, :create, :reply, :show, :inbox, :outbox, :mark, :destroy], Message
      can [:close, :reopen], Note
      can [:new, :create], Report
      can [:mine, :new, :create, :edit, :update, :delete, :api_create, :api_read, :api_update, :api_delete, :api_data], Trace
      can [:account, :go_public, :make_friend, :remove_friend, :api_details, :api_gpx_files], User
      can [:read, :read_one, :update, :update_one, :delete_one], UserPreference

      if user.terms_agreed? || !REQUIRE_TERMS_AGREED
        can [:create, :update, :upload, :close, :subscribe, :unsubscribe, :expand_bbox], Changeset
        can :create, ChangesetComment
      end

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
        can [:set_status, :delete, :index], User
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

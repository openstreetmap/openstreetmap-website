# frozen_string_literal: true

class ApiCapability
  include CanCan::Ability

  def initialize(token)
    if Settings.status != "database_offline"
      user = if token.respond_to?(:resource_owner_id)
               User.find(token.resource_owner_id)
             elsif token.respond_to?(:user)
               token.user
             end

      can [:create, :comment, :close, :reopen], Note if scope?(token, :write_notes)
      can [:show, :data], Trace if scope?(token, :read_gpx)
      can [:create, :update, :destroy], Trace if scope?(token, :write_gpx)
      can [:details], User if scope?(token, :read_prefs)
      can [:gpx_files], User if scope?(token, :read_gpx)
      can [:index, :show], UserPreference if scope?(token, :read_prefs)
      can [:update, :update_all, :destroy], UserPreference if scope?(token, :write_prefs)

      if user&.terms_agreed?
        can [:create, :update, :upload, :close, :subscribe, :unsubscribe], Changeset if scope?(token, :write_api)
        can :create, ChangesetComment if scope?(token, :write_api)
        can [:create, :update, :delete], Node if scope?(token, :write_api)
        can [:create, :update, :delete], Way if scope?(token, :write_api)
        can [:create, :update, :delete], Relation if scope?(token, :write_api)
      end

      if user&.moderator?
        can [:destroy, :restore], ChangesetComment if scope?(token, :write_api)
        can :destroy, Note if scope?(token, :write_notes)
        if user&.terms_agreed?
          can :redact, OldNode if scope?(token, :write_api)
          can :redact, OldWay if scope?(token, :write_api)
          can :redact, OldRelation if scope?(token, :write_api)
        end
      end
    end
  end

  private

  def scope?(token, scope)
    token&.includes_scope?(scope)
  end
end

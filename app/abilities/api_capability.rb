# frozen_string_literal: true

class ApiCapability
  include CanCan::Ability

  def initialize(token)
    if Settings.status != "database_offline"
      user = User.find(token.resource_owner_id)

      if user&.active?
        can [:create, :comment, :close, :reopen], Note if scope?(token, :write_notes)
        can [:create, :destroy], NoteSubscription if scope?(token, :write_notes)
        can [:show, :data], Trace if scope?(token, :read_gpx)
        can [:create, :update, :destroy], Trace if scope?(token, :write_gpx)
        can [:details], User if scope?(token, :read_prefs)
        can [:gpx_files], User if scope?(token, :read_gpx)
        can [:index, :show], UserPreference if scope?(token, :read_prefs)
        can [:update, :update_all, :destroy], UserPreference if scope?(token, :write_prefs)
        can [:inbox, :outbox, :show, :update, :destroy], Message if scope?(token, :consume_messages)
        can [:create], Message if scope?(token, :send_messages)

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
  end

  private

  def scope?(token, scope)
    token&.includes_scope?(scope)
  end
end

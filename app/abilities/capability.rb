# frozen_string_literal: true

class Capability
  include CanCan::Ability

  def initialize(token)
    can [:create, :comment, :close, :reopen], Note if capability?(token, :allow_write_notes)
    can [:api_read, :api_data], Trace if capability?(token, :allow_read_gpx)
    can [:api_create, :api_update, :api_delete], Trace if capability?(token, :allow_write_gpx)
    can [:api_details], User if capability?(token, :allow_read_prefs)
    can [:api_gpx_files], User if capability?(token, :allow_read_gpx)
    can [:read, :read_one], UserPreference if capability?(token, :allow_read_prefs)
    can [:update, :update_one, :delete_one], UserPreference if capability?(token, :allow_write_prefs)

    if token&.user&.terms_agreed? || !REQUIRE_TERMS_AGREED
      can [:create, :update, :upload, :close, :subscribe, :unsubscribe, :expand_bbox], Changeset if capability?(token, :allow_write_api)
      can :create, ChangesetComment if capability?(token, :allow_write_api)
      can [:create, :update, :delete], Node if capability?(token, :allow_write_api)
      can [:create, :update, :delete], Way if capability?(token, :allow_write_api)
      can [:create, :update, :delete], Relation if capability?(token, :allow_write_api)
    end

    if token&.user&.moderator?
      can [:destroy, :restore], ChangesetComment if capability?(token, :allow_write_api)
      can :destroy, Note if capability?(token, :allow_write_notes)
      if token&.user&.terms_agreed? || !REQUIRE_TERMS_AGREED
        can :redact, OldNode if capability?(token, :allow_write_api)
        can :redact, OldWay if capability?(token, :allow_write_api)
        can :redact, OldRelation if capability?(token, :allow_write_api)
      end
    end
  end

  private

  def capability?(token, cap)
    token&.read_attribute(cap)
  end
end

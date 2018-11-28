# frozen_string_literal: true

class Capability
  include CanCan::Ability

  def initialize(token)
    can :create, ChangesetComment if capability?(token, :allow_write_api)
    can [:read, :read_one], UserPreference if capability?(token, :allow_read_prefs)
    can [:update, :update_one, :delete_one], UserPreference if capability?(token, :allow_write_prefs)

    if token&.user&.moderator?
      can [:destroy, :restore], ChangesetComment if capability?(token, :allow_write_api)
    end
  end

  private

  def capability?(token, cap)
    token&.read_attribute(cap)
  end
end

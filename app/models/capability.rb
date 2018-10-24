# frozen_string_literal: true

class Capability
  include CanCan::Ability

  def initialize(user, token)
    if user
      can [:read, :read_one], UserPreference if capability?(token, :allow_read_prefs)
      can [:update, :update_one, :delete_one], UserPreference if capability?(token, :allow_write_prefs)
    end
  end

  private

  def capability?(token, cap)
    token&.read_attribute(cap)
  end
end

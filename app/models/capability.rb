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

  # If a user provides no tokens, they've authenticated via a non-oauth method
  # and permission to access to all capabilities is assumed.
  def capability?(token, cap)
    token.nil? || token.read_attribute(cap)
  end
end

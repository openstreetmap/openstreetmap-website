# frozen_string_literal: true

require "test_helper"

class UserApiCapabilityTest < ActiveSupport::TestCase
  test "user preferences" do
    user = create(:user)
    scopes = Set.new
    ability = ApiAbility.new user, scopes

    [:index, :show, :update_all, :update, :destroy].each do |act|
      assert ability.cannot? act, UserPreference
    end

    scopes = Set.new %w[read_prefs]
    ability = ApiAbility.new user, scopes

    [:update_all, :update, :destroy].each do |act|
      assert ability.cannot? act, UserPreference
    end

    [:index, :show].each do |act|
      assert ability.can? act, UserPreference
    end

    scopes = Set.new %w[write_prefs]
    ability = ApiAbility.new user, scopes

    [:index, :show].each do |act|
      assert ability.cannot? act, UserPreference
    end

    [:update_all, :update, :destroy].each do |act|
      assert ability.can? act, UserPreference
    end
  end
end

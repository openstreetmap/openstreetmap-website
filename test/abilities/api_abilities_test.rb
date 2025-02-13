# frozen_string_literal: true

require "test_helper"

class ApiAbilityTest < ActiveSupport::TestCase
end

class GuestApiAbilityTest < ApiAbilityTest
  test "note permissions for a guest" do
    scopes = Set.new
    ability = ApiAbility.new nil, scopes

    [:index, :create, :feed, :show, :search].each do |action|
      assert ability.can?(action, Note), "should be able to #{action} Notes"
    end

    [:comment, :close, :reopen, :destroy].each do |action|
      assert ability.cannot?(action, Note), "should not be able to #{action} Notes"
    end
  end
end

class UserApiAbilityTest < ApiAbilityTest
  test "Note permissions" do
    user = create(:user)
    scopes = Set.new %w[write_notes]
    ability = ApiAbility.new user, scopes

    [:index, :create, :comment, :feed, :show, :search, :close, :reopen].each do |action|
      assert ability.can?(action, Note), "should be able to #{action} Notes"
    end

    [:destroy].each do |action|
      assert ability.cannot?(action, Note), "should not be able to #{action} Notes"
    end
  end
end

class ModeratorApiAbilityTest < ApiAbilityTest
  test "Note permissions" do
    user = create(:moderator_user)
    scopes = Set.new %w[write_notes]
    ability = ApiAbility.new user, scopes

    [:index, :create, :comment, :feed, :show, :search, :close, :reopen, :destroy].each do |action|
      assert ability.can?(action, Note), "should be able to #{action} Notes"
    end
  end
end

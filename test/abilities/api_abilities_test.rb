# frozen_string_literal: true

require "test_helper"

class ApiAbilityTest < ActiveSupport::TestCase
end

class GuestApiAbilityTest < ApiAbilityTest
  test "note permissions for a guest" do
    ability = ApiAbility.new nil

    [:index, :create, :comment, :feed, :show, :search].each do |action|
      assert ability.can?(action, Note), "should be able to #{action} Notes"
    end

    [:close, :reopen, :destroy].each do |action|
      assert ability.cannot?(action, Note), "should not be able to #{action} Notes"
    end
  end
end

class UserApiAbilityTest < ApiAbilityTest
  test "Note permissions" do
    ability = ApiAbility.new create(:user)

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
    ability = ApiAbility.new create(:moderator_user)

    [:index, :create, :comment, :feed, :show, :search, :close, :reopen, :destroy].each do |action|
      assert ability.can?(action, Note), "should be able to #{action} Notes"
    end
  end
end

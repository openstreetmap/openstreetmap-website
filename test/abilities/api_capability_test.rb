# frozen_string_literal: true

require "test_helper"

class ChangesetCommentApiCapabilityTest < ActiveSupport::TestCase
  test "as a normal user with permissionless token" do
    user = create(:user)
    token = create(:oauth_access_token, :user => user)
    ability = ApiAbility.new user, token

    [:create, :destroy, :restore].each do |action|
      assert ability.cannot? action, ChangesetComment
    end
  end

  test "as a normal user with write_api token" do
    user = create(:user)
    token = create(:oauth_access_token, :user => user, :scopes => %w[write_api])
    ability = ApiAbility.new user, token

    [:destroy, :restore].each do |action|
      assert ability.cannot? action, ChangesetComment
    end

    [:create].each do |action|
      assert ability.can? action, ChangesetComment
    end
  end

  test "as a moderator with permissionless token" do
    user = create(:moderator_user)
    token = create(:oauth_access_token, :user => user)
    ability = ApiAbility.new user, token

    [:create, :destroy, :restore].each do |action|
      assert ability.cannot? action, ChangesetComment
    end
  end

  test "as a moderator with write_api token" do
    user = create(:moderator_user)
    token = create(:oauth_access_token, :user => user, :scopes => %w[write_api])
    ability = ApiAbility.new user, token

    [:create, :destroy, :restore].each do |action|
      assert ability.can? action, ChangesetComment
    end
  end
end

class NoteApiCapabilityTest < ActiveSupport::TestCase
  test "as a normal user with permissionless token" do
    user = create(:user)
    token = create(:oauth_access_token, :user => user)
    ability = ApiAbility.new user, token

    [:create, :comment, :close, :reopen, :destroy].each do |action|
      assert ability.cannot? action, Note
    end
  end

  test "as a normal user with write_notes token" do
    user = create(:user)
    token = create(:oauth_access_token, :user => user, :scopes => %w[write_notes])
    ability = ApiAbility.new user, token

    [:destroy].each do |action|
      assert ability.cannot? action, Note
    end

    [:create, :comment, :close, :reopen].each do |action|
      assert ability.can? action, Note
    end
  end

  test "as a moderator with permissionless token" do
    user = create(:moderator_user)
    token = create(:oauth_access_token, :user => user)
    ability = ApiAbility.new user, token

    [:destroy].each do |action|
      assert ability.cannot? action, Note
    end
  end

  test "as a moderator with write_notes token" do
    user = create(:moderator_user)
    token = create(:oauth_access_token, :user => user, :scopes => %w[write_notes])
    ability = ApiAbility.new user, token

    [:destroy].each do |action|
      assert ability.can? action, Note
    end
  end
end

class UserApiCapabilityTest < ActiveSupport::TestCase
  test "user preferences" do
    # A user with empty tokens
    user = create(:user)
    token = create(:oauth_access_token, :user => user)
    ability = ApiAbility.new user, token

    [:index, :show, :update_all, :update, :destroy].each do |act|
      assert ability.cannot? act, UserPreference
    end

    token = create(:oauth_access_token, :user => user, :scopes => %w[read_prefs])
    ability = ApiAbility.new user, token

    [:update_all, :update, :destroy].each do |act|
      assert ability.cannot? act, UserPreference
    end

    [:index, :show].each do |act|
      assert ability.can? act, UserPreference
    end

    token = create(:oauth_access_token, :user => user, :scopes => %w[write_prefs])
    ability = ApiAbility.new user, token

    [:index, :show].each do |act|
      assert ability.cannot? act, UserPreference
    end

    [:update_all, :update, :destroy].each do |act|
      assert ability.can? act, UserPreference
    end
  end
end

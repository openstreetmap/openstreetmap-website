# frozen_string_literal: true

require "test_helper"

class ChangesetCommentApiCapabilityTest < ActiveSupport::TestCase
  test "as a normal user with permissionless token" do
    token = create(:oauth_access_token)
    capability = ApiCapability.new token

    [:create, :destroy, :restore].each do |action|
      assert capability.cannot? action, ChangesetComment
    end
  end

  test "as a normal user with write_api token" do
    token = create(:oauth_access_token, :scopes => %w[write_api])
    capability = ApiCapability.new token

    [:destroy, :restore].each do |action|
      assert capability.cannot? action, ChangesetComment
    end

    [:create].each do |action|
      assert capability.can? action, ChangesetComment
    end
  end

  test "as a moderator with permissionless token" do
    token = create(:oauth_access_token, :resource_owner_id => create(:moderator_user).id)
    capability = ApiCapability.new token

    [:create, :destroy, :restore].each do |action|
      assert capability.cannot? action, ChangesetComment
    end
  end

  test "as a moderator with write_api token" do
    token = create(:oauth_access_token, :resource_owner_id => create(:moderator_user).id, :scopes => %w[write_api])
    capability = ApiCapability.new token

    [:create, :destroy, :restore].each do |action|
      assert capability.can? action, ChangesetComment
    end
  end
end

class NoteApiCapabilityTest < ActiveSupport::TestCase
  test "as a normal user with permissionless token" do
    token = create(:oauth_access_token)
    capability = ApiCapability.new token

    [:create, :comment, :close, :reopen, :destroy].each do |action|
      assert capability.cannot? action, Note
    end
  end

  test "as a normal user with write_notes token" do
    token = create(:oauth_access_token, :scopes => %w[write_notes])
    capability = ApiCapability.new token

    [:destroy].each do |action|
      assert capability.cannot? action, Note
    end

    [:create, :comment, :close, :reopen].each do |action|
      assert capability.can? action, Note
    end
  end

  test "as a moderator with permissionless token" do
    token = create(:oauth_access_token, :resource_owner_id => create(:moderator_user).id)
    capability = ApiCapability.new token

    [:destroy].each do |action|
      assert capability.cannot? action, Note
    end
  end

  test "as a moderator with write_notes token" do
    token = create(:oauth_access_token, :resource_owner_id => create(:moderator_user).id, :scopes => %w[write_notes])
    capability = ApiCapability.new token

    [:destroy].each do |action|
      assert capability.can? action, Note
    end
  end
end

class UserApiCapabilityTest < ActiveSupport::TestCase
  test "user preferences" do
    # A user with empty tokens
    token = create(:oauth_access_token)
    capability = ApiCapability.new token

    [:index, :show, :update_all, :update, :destroy].each do |act|
      assert capability.cannot? act, UserPreference
    end

    token = create(:oauth_access_token, :scopes => %w[read_prefs])
    capability = ApiCapability.new token

    [:update_all, :update, :destroy].each do |act|
      assert capability.cannot? act, UserPreference
    end

    [:index, :show].each do |act|
      assert capability.can? act, UserPreference
    end

    token = create(:oauth_access_token, :scopes => %w[write_prefs])
    capability = ApiCapability.new token

    [:index, :show].each do |act|
      assert capability.cannot? act, UserPreference
    end

    [:update_all, :update, :destroy].each do |act|
      assert capability.can? act, UserPreference
    end
  end
end

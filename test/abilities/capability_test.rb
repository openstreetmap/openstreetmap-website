# frozen_string_literal: true

require "test_helper"

class CapabilityTest < ActiveSupport::TestCase
  def tokens(*toks)
    AccessToken.new do |token|
      toks.each do |t|
        token.public_send("#{t}=", true)
      end
    end
  end
end

class ChangesetCommentCapabilityTest < CapabilityTest
  test "as a normal user with permissionless token" do
    token = create(:access_token)
    capability = Capability.new token

    [:create, :destroy, :restore].each do |action|
      assert capability.cannot? action, ChangesetComment
    end
  end

  test "as a normal user with allow_write_api token" do
    token = create(:access_token, :allow_write_api => true)
    capability = Capability.new token

    [:destroy, :restore].each do |action|
      assert capability.cannot? action, ChangesetComment
    end

    [:create].each do |action|
      assert capability.can? action, ChangesetComment
    end
  end

  test "as a moderator with permissionless token" do
    token = create(:access_token, :user => create(:moderator_user))
    capability = Capability.new token

    [:create, :destroy, :restore].each do |action|
      assert capability.cannot? action, ChangesetComment
    end
  end

  test "as a moderator with allow_write_api token" do
    token = create(:access_token, :user => create(:moderator_user), :allow_write_api => true)
    capability = Capability.new token

    [:create, :destroy, :restore].each do |action|
      assert capability.can? action, ChangesetComment
    end
  end
end

class UserCapabilityTest < CapabilityTest
  test "user preferences" do
    # a user with no tokens
    capability = Capability.new nil
    [:read, :read_one, :update, :update_one, :delete_one].each do |act|
      assert capability.cannot? act, UserPreference
    end

    # A user with empty tokens
    capability = Capability.new tokens

    [:read, :read_one, :update, :update_one, :delete_one].each do |act|
      assert capability.cannot? act, UserPreference
    end

    capability = Capability.new tokens(:allow_read_prefs)

    [:update, :update_one, :delete_one].each do |act|
      assert capability.cannot? act, UserPreference
    end

    [:read, :read_one].each do |act|
      assert capability.can? act, UserPreference
    end

    capability = Capability.new tokens(:allow_write_prefs)
    [:read, :read_one].each do |act|
      assert capability.cannot? act, UserPreference
    end

    [:update, :update_one, :delete_one].each do |act|
      assert capability.can? act, UserPreference
    end
  end
end

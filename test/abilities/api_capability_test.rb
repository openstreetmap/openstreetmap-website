# frozen_string_literal: true

require "test_helper"

class ApiCapabilityTest < ActiveSupport::TestCase
  def tokens(*toks)
    AccessToken.new do |token|
      toks.each do |t|
        token.public_send("#{t}=", true)
      end
    end
  end
end

class ChangesetCommentApiCapabilityTest < ApiCapabilityTest
  test "as a normal user with permissionless token" do
    token = create(:access_token)
    capability = ApiCapability.new token

    [:create, :destroy, :restore].each do |action|
      assert capability.cannot? action, ChangesetComment
    end
  end

  test "as a normal user with allow_write_api token" do
    token = create(:access_token, :allow_write_api => true)
    capability = ApiCapability.new token

    [:destroy, :restore].each do |action|
      assert capability.cannot? action, ChangesetComment
    end

    [:create].each do |action|
      assert capability.can? action, ChangesetComment
    end
  end

  test "as a moderator with permissionless token" do
    token = create(:access_token, :user => create(:moderator_user))
    capability = ApiCapability.new token

    [:create, :destroy, :restore].each do |action|
      assert capability.cannot? action, ChangesetComment
    end
  end

  test "as a moderator with allow_write_api token" do
    token = create(:access_token, :user => create(:moderator_user), :allow_write_api => true)
    capability = ApiCapability.new token

    [:create, :destroy, :restore].each do |action|
      assert capability.can? action, ChangesetComment
    end
  end
end

class NoteApiCapabilityTest < ApiCapabilityTest
  test "as a normal user with permissionless token" do
    token = create(:access_token)
    capability = ApiCapability.new token

    [:create, :comment, :close, :reopen, :destroy].each do |action|
      assert capability.cannot? action, Note
    end
  end

  test "as a normal user with allow_write_notes token" do
    token = create(:access_token, :allow_write_notes => true)
    capability = ApiCapability.new token

    [:destroy].each do |action|
      assert capability.cannot? action, Note
    end

    [:create, :comment, :close, :reopen].each do |action|
      assert capability.can? action, Note
    end
  end

  test "as a moderator with permissionless token" do
    token = create(:access_token, :user => create(:moderator_user))
    capability = ApiCapability.new token

    [:destroy].each do |action|
      assert capability.cannot? action, Note
    end
  end

  test "as a moderator with allow_write_notes token" do
    token = create(:access_token, :user => create(:moderator_user), :allow_write_notes => true)
    capability = ApiCapability.new token

    [:destroy].each do |action|
      assert capability.can? action, Note
    end
  end
end

class UserApiCapabilityTest < ApiCapabilityTest
  test "user preferences" do
    # a user with no tokens
    capability = ApiCapability.new nil
    [:index, :show, :update_all, :update, :destroy].each do |act|
      assert capability.cannot? act, UserPreference
    end

    # A user with empty tokens
    capability = ApiCapability.new tokens

    [:index, :show, :update_all, :update, :destroy].each do |act|
      assert capability.cannot? act, UserPreference
    end

    capability = ApiCapability.new tokens(:allow_read_prefs)

    [:update_all, :update, :destroy].each do |act|
      assert capability.cannot? act, UserPreference
    end

    [:index, :show].each do |act|
      assert capability.can? act, UserPreference
    end

    capability = ApiCapability.new tokens(:allow_write_prefs)
    [:index, :show].each do |act|
      assert capability.cannot? act, UserPreference
    end

    [:update_all, :update, :destroy].each do |act|
      assert capability.can? act, UserPreference
    end
  end
end

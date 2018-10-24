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

class UserCapabilityTest < CapabilityTest
  test "user preferences" do
    user = create(:user)

    # a user with no tokens
    capability = Capability.new create(:user), nil
    [:read, :read_one, :update, :update_one, :delete_one].each do |act|
      assert capability.cannot? act, UserPreference
    end

    # A user with empty tokens
    capability = Capability.new create(:user), tokens

    [:read, :read_one, :update, :update_one, :delete_one].each do |act|
      assert capability.cannot? act, UserPreference
    end

    capability = Capability.new user, tokens(:allow_read_prefs)

    [:update, :update_one, :delete_one].each do |act|
      assert capability.cannot? act, UserPreference
    end

    [:read, :read_one].each do |act|
      assert capability.can? act, UserPreference
    end

    capability = Capability.new user, tokens(:allow_write_prefs)
    [:read, :read_one].each do |act|
      assert capability.cannot? act, UserPreference
    end

    [:update, :update_one, :delete_one].each do |act|
      assert capability.can? act, UserPreference
    end
  end
end

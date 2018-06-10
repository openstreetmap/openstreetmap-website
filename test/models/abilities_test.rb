# frozen_string_literal: true

require "test_helper"

class AbilityTest < ActiveSupport::TestCase

  def tokens(*toks)
    AccessToken.new do |token|
      toks.each do |t|
        token.public_send("#{t}=", true)
      end
    end
  end

end

class GuestAbilityTest < AbilityTest

  test "diary permissions for a guest" do
    ability = Ability.new nil, tokens
    [:list, :rss, :view, :comments].each do |action|
      assert ability.can?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
    end

    [:create, :edit, :comment, :subscribe, :unsubscribe, :hide, :hidecomment].each do |action|
      assert ability.cannot?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
      assert ability.cannot?(action, DiaryComment), "should be able to #{action} DiaryEntries"
    end
  end

end

class UserAbilityTest < AbilityTest

  test "Diary permissions" do
    ability = Ability.new create(:user), tokens

    [:list, :rss, :view, :comments, :create, :edit, :comment, :subscribe, :unsubscribe].each do |action|
      assert ability.can?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
    end

    [:hide, :hidecomment].each do |action|
      assert ability.cannot?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
      assert ability.cannot?(action, DiaryComment), "should be able to #{action} DiaryEntries"
    end
  end

  test "user preferences" do
    user = create(:user)

    # a user with no tokens
    ability = Ability.new create(:user), nil
    [:read, :read_one, :update, :update_one, :delete_one].each do |act|
      assert ability.can? act, UserPreference
    end

    # A user with empty tokens
    ability = Ability.new create(:user), tokens

    [:read, :read_one, :update, :update_one, :delete_one].each do |act|
      assert ability.cannot? act, UserPreference
    end

    ability = Ability.new user, tokens(:allow_read_prefs)

    [:update, :update_one, :delete_one].each do |act|
      assert ability.cannot? act, UserPreference
    end

    [:read, :read_one].each do |act|
      assert ability.can? act, UserPreference
    end

    ability = Ability.new user, tokens(:allow_write_prefs)
    [:read, :read_one].each do |act|
      assert ability.cannot? act, UserPreference
    end

    [:update, :update_one, :delete_one].each do |act|
      assert ability.can? act, UserPreference
    end
  end
end

class AdministratorAbilityTest < AbilityTest

  test "Diary for an administrator" do
    ability = Ability.new create(:administrator_user), tokens
    [:list, :rss, :view, :comments, :create, :edit, :comment, :subscribe, :unsubscribe, :hide, :hidecomment].each do |action|
      assert ability.can?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
    end

    [:hide, :hidecomment].each do |action|
      assert ability.can?(action, DiaryComment), "should be able to #{action} DiaryComment"
    end
  end

  test "administrator does not auto-grant user preferences" do
    ability = Ability.new create(:administrator_user), tokens

    [:read, :read_one, :update, :update_one, :delete_one].each do |act|
      assert ability.cannot? act, UserPreference
    end
  end


end

# frozen_string_literal: true

require "test_helper"

class GuestAbilityTest < ActiveSupport::TestCase
  test "search permissions for a guest" do
    ability = Ability.new nil

    [:create, :show].each do |action|
      assert ability.can?(action, :search), "should be able to #{action} searches"
    end
  end

  test "diary permissions for a guest" do
    ability = Ability.new nil
    [:index, :rss, :show].each do |action|
      assert ability.can?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
    end

    [:index].each do |action|
      assert ability.can?(action, DiaryComment), "should be able to #{action} DiaryComments"
    end

    [:create, :edit, :subscribe, :unsubscribe, :hide, :unhide].each do |action|
      assert ability.cannot?(action, DiaryEntry), "should not be able to #{action} DiaryEntries"
    end

    [:create, :hide, :unhide].each do |action|
      assert ability.cannot?(action, DiaryComment), "should not be able to #{action} DiaryComments"
    end
  end

  test "note permissions for a guest" do
    ability = Ability.new nil

    [:index].each do |action|
      assert ability.can?(action, Note), "should be able to #{action} Notes"
    end
  end

  test "user roles permissions for a guest" do
    ability = Ability.new nil

    [:create, :destroy].each do |action|
      assert ability.cannot?(action, UserRole), "should not be able to #{action} UserRoles"
    end
  end
end

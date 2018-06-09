# frozen_string_literal: true

require "test_helper"

class AbilityTest < ActiveSupport::TestCase

  test "diary permissions for a guest" do
    ability = Ability.new(nil, [])
    [:list, :rss, :view, :comments].each do |action|
      assert ability.can?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
    end

    [:create, :edit, :comment, :subscribe, :unsubscribe, :hide, :hidecomment].each do |action|
      assert ability.cannot?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
      assert ability.cannot?(action, DiaryComment), "should be able to #{action} DiaryEntries"
    end
  end


  test "Diary permissions for a normal user" do
    ability = Ability.new(create(:user), [])

    [:list, :rss, :view, :comments, :create, :edit, :comment, :subscribe, :unsubscribe].each do |action|
      assert ability.can?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
    end

    [:hide, :hidecomment].each do |action|
      assert ability.cannot?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
      assert ability.cannot?(action, DiaryComment), "should be able to #{action} DiaryEntries"
    end
  end

  test "Diary for an administrator" do
    ability = Ability.new(create(:administrator_user), [])
    [:list, :rss, :view, :comments, :create, :edit, :comment, :subscribe, :unsubscribe, :hide, :hidecomment].each do |action|
      assert ability.can?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
    end

    [:hide, :hidecomment].each do |action|
      assert ability.can?(action, DiaryComment), "should be able to #{action} DiaryComment"
    end
  end
end

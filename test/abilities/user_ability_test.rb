# frozen_string_literal: true

require "test_helper"

class UserAbilityTest < ActiveSupport::TestCase
  test "Diary permissions" do
    ability = Ability.new create(:user)

    [:index, :rss, :show, :create, :edit, :subscribe, :unsubscribe].each do |action|
      assert ability.can?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
    end

    [:index, :create].each do |action|
      assert ability.can?(action, DiaryComment), "should be able to #{action} DiaryComments"
    end

    [:hide, :unhide].each do |action|
      assert ability.cannot?(action, DiaryEntry), "should not be able to #{action} DiaryEntries"
      assert ability.cannot?(action, DiaryComment), "should not be able to #{action} DiaryComment"
    end

    [:index, :show, :resolve, :ignore, :reopen].each do |action|
      assert ability.cannot?(action, Issue), "should not be able to #{action} Issues"
    end
  end
end

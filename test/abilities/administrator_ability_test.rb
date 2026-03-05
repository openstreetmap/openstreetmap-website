# frozen_string_literal: true

require "test_helper"

class AdministratorAbilityTest < ActiveSupport::TestCase
  test "Diary for an administrator" do
    ability = Ability.new create(:administrator_user)
    [:index, :rss, :show, :create, :edit, :subscribe, :unsubscribe, :hide, :unhide].each do |action|
      assert ability.can?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
    end

    [:index, :create, :hide, :unhide].each do |action|
      assert ability.can?(action, DiaryComment), "should be able to #{action} DiaryComments"
    end
  end

  test "User Roles permissions for an administrator" do
    ability = Ability.new create(:administrator_user)

    [:create, :destroy].each do |action|
      assert ability.can?(action, UserRole), "should be able to #{action} UserRoles"
    end
  end
end

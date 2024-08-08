# frozen_string_literal: true

require "test_helper"

class AbilityTest < ActiveSupport::TestCase
end

class GuestAbilityTest < AbilityTest
  test "geocoder permission for a guest" do
    ability = Ability.new nil

    [:search, :search_latlon, :search_osm_nominatim,
     :search_osm_nominatim_reverse].each do |action|
      assert ability.can?(action, :geocoder), "should be able to #{action} geocoder"
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

  test "community permissions for a guest" do
    ability = Ability.new nil

    [:index, :show].each do |action|
      assert ability.can?(action, Community), "should be able to #{action} Communities"
    end

    [:edit, :update].each do |action|
      assert ability.cannot?(action, Community), "should not be able to #{action} Communities"
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

    [:grant, :revoke].each do |action|
      assert ability.cannot?(action, UserRole), "should not be able to #{action} UserRoles"
    end
  end
end

class UserAbilityTest < AbilityTest
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

  test "community permissions for a user" do
    community = create_community_with_organizer
    ability_as_org = Ability.new(community.leader)
    ability_as_nonorg = Ability.new create(:user)

    [:edit, :update].each do |action|
      assert ability_as_org.can?(action, community), "should be able to #{action} this community"
      assert ability_as_nonorg.cannot?(action, community), "should not be able to #{action} this community"
    end
  end
end

class ModeratorAbilityTest < AbilityTest
  test "Issue permissions" do
    ability = Ability.new create(:moderator_user)

    [:index, :show, :resolve, :ignore, :reopen].each do |action|
      assert ability.can?(action, Issue), "should be able to #{action} Issues"
    end
  end

  test "User Roles permissions" do
    ability = Ability.new create(:moderator_user)

    [:grant, :revoke].each do |action|
      assert ability.cannot?(action, UserRole), "should not be able to #{action} UserRoles"
    end

    [:hide, :unhide].each do |action|
      assert ability.can?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
      assert ability.can?(action, DiaryComment), "should be able to #{action} DiaryComment"
    end
  end
end

class AdministratorAbilityTest < AbilityTest
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

    [:grant, :revoke].each do |action|
      assert ability.can?(action, UserRole), "should be able to #{action} UserRoles"
    end
  end
end

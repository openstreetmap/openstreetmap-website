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

    [:create, :destroy].each do |action|
      assert ability.cannot?(action, UserRole), "should not be able to #{action} UserRoles"
    end

    [:hide, :unhide].each do |action|
      assert ability.can?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
      assert ability.can?(action, DiaryComment), "should be able to #{action} DiaryComment"
    end
  end

  test "Active block update permissions" do
    creator_user = create(:moderator_user)
    other_moderator_user = create(:moderator_user)
    block = create(:user_block, :creator => creator_user)

    creator_ability = Ability.new creator_user
    assert creator_ability.can?(:edit, block)
    assert creator_ability.can?(:update, block)

    other_moderator_ability = Ability.new other_moderator_user
    assert other_moderator_ability.can?(:edit, block)
    assert other_moderator_ability.can?(:update, block)
  end

  test "Expired block update permissions" do
    creator_user = create(:moderator_user)
    other_moderator_user = create(:moderator_user)
    block = create(:user_block, :expired, :creator => creator_user)

    creator_ability = Ability.new creator_user
    assert creator_ability.can?(:edit, block)
    assert creator_ability.can?(:update, block)

    other_moderator_ability = Ability.new other_moderator_user
    assert other_moderator_ability.cannot?(:edit, block)
    assert other_moderator_ability.cannot?(:update, block)
  end

  test "Revoked block update permissions" do
    creator_user = create(:moderator_user)
    revoker_user = create(:moderator_user)
    other_moderator_user = create(:moderator_user)
    block = create(:user_block, :revoked, :creator => creator_user, :revoker => revoker_user)

    creator_ability = Ability.new creator_user
    assert creator_ability.can?(:edit, block)
    assert creator_ability.can?(:update, block)

    revoker_ability = Ability.new revoker_user
    assert revoker_ability.can?(:edit, block)
    assert revoker_ability.can?(:update, block)

    other_moderator_ability = Ability.new other_moderator_user
    assert other_moderator_ability.cannot?(:edit, block)
    assert other_moderator_ability.cannot?(:update, block)
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

    [:create, :destroy].each do |action|
      assert ability.can?(action, UserRole), "should be able to #{action} UserRoles"
    end
  end
end

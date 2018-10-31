# frozen_string_literal: true

require "test_helper"

class AbilityTest < ActiveSupport::TestCase
end

class GuestAbilityTest < AbilityTest
  test "geocoder permission for a guest" do
    ability = Ability.new nil

    [:search, :search_latlon, :search_ca_postcode, :search_osm_nominatim,
     :search_geonames, :search_osm_nominatim_reverse, :search_geonames_reverse].each do |action|
      assert ability.can?(action, :geocoder), "should be able to #{action} geocoder"
    end
  end

  test "diary permissions for a guest" do
    ability = Ability.new nil
    [:index, :rss, :show, :comments].each do |action|
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
    ability = Ability.new create(:user)

    [:index, :rss, :show, :comments, :create, :edit, :comment, :subscribe, :unsubscribe].each do |action|
      assert ability.can?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
    end

    [:hide, :hidecomment].each do |action|
      assert ability.cannot?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
      assert ability.cannot?(action, DiaryComment), "should be able to #{action} DiaryEntries"
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
end

class AdministratorAbilityTest < AbilityTest
  test "Diary for an administrator" do
    ability = Ability.new create(:administrator_user)
    [:index, :rss, :show, :comments, :create, :edit, :comment, :subscribe, :unsubscribe, :hide, :hidecomment].each do |action|
      assert ability.can?(action, DiaryEntry), "should be able to #{action} DiaryEntries"
    end

    [:hide, :hidecomment].each do |action|
      assert ability.can?(action, DiaryComment), "should be able to #{action} DiaryComment"
    end
  end
end

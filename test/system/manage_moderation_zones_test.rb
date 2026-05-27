# frozen_string_literal: true

require "application_system_test_case"

class ManageModerationZones < ApplicationSystemTestCase
  test "Create a moderation zone and fail to put an anonymous note within it" do
    sign_in_as(create(:moderator_user))

    visit moderation_zones_path
    click_on "New Moderation Zone"

    fill_in "Name", :with => "Test zone"
    fill_in "Reason", :with => "He's a very naughty boy"

    map = find_by_id("map")
    map.click(:offset => :center, :x => -50, :y => -50)
    map.click(:offset => :center, :x =>   0, :y => -50)
    map.click(:offset => :center, :x =>   0, :y =>   0)
    map.click(:offset => :center, :x => -50, :y =>   0)
    map.click(:offset => :center, :x => -50, :y => -50)

    select "1 week", :from => :moderation_zone_period
    click_on "Create Moderation zone"
    assert_content "Moderation zone created"

    sign_out
    visit new_note_path(:anchor => "map=18/7.15/-9.23")
    within_sidebar do
      fill_in "text", :with => "Hahaha! Nobody expects the Spanish anonymous notes!"
      click_on "Add Note"

      assert_content "There was an error when creating the note"
    end
  end
end

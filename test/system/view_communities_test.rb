require "application_system_test_case"

class ViewCommunitiesTest < ApplicationSystemTestCase
  def test_lc_links
    # Check that all the parsing of the chapter information has worked
    visit "/communities_index"
    assert_link "OpenStreetMap US", :href => "https://www.openstreetmap.us/"
    assert_link "OpenStreetMap Belgium", :href => "https://openstreetmap.be/"
  end

  def test_translated_links
    sign_in_as(create(:user))

    visit edit_preferences_path
    fill_in "Preferred Languages", :with => "fr"
    click_on "Update Preferences"

    visit "/communities_index"
    assert_link "OpenStreetMap États-Unis", :href => "https://www.openstreetmap.us/"
    assert_link "OpenStreetMap Belgique", :href => "https://openstreetmap.be/"
  end
end

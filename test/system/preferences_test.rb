require "application_system_test_case"

class PreferencesTest < ApplicationSystemTestCase
  def test_flash_message_shows_in_original_language
    sign_in_as(create(:user))

    visit edit_preferences_path
    click_on "Update Preferences"

    assert_content "Preferences updated"
  end

  def test_flash_message_shows_in_new_language
    sign_in_as(create(:user))

    visit edit_preferences_path
    fill_in "Preferred Languages", :with => "fr"
    click_on "Update Preferences"

    assert_content "Préférences mises à jour"
  end
end

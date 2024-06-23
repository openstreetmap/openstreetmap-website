require "application_system_test_case"

class PreferencesTest < ApplicationSystemTestCase
  def setup
    create(:language, :code => "en")
    create(:language, :code => "fr", :english_name => "French", :native_name => "Français")
    create(:language, :code => "de", :english_name => "German", :native_name => "Deutsch")
  end

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

  def test_language_dropdown
    user = create(:user, :languages => %w[en fr])
    sign_in_as(user)

    visit edit_preferences_path
    assert_field "Preferred Languages", :with => "en fr"

    select "French", :from => "Available Languages"
    assert_no_button "Add"
    assert_button "Remove"

    click_on "Remove"
    assert_field "Preferred Languages", :with => "en"
    assert_button "Add"
    assert_no_button "Remove"

    click_on "Add"
    assert_field "Preferred Languages", :with => "fr en"
    assert_no_button "Add"
    assert_button "Remove"

    fill_in "Preferred Languages", :with => "de en"
    assert_button "Add"
    assert_no_button "Remove"
  end
end

# frozen_string_literal: true

require "application_system_test_case"

class PreferencesTest < ApplicationSystemTestCase
  test "shown English as selected language when user has unknown language in preferences" do
    sign_in_as(create(:user, :languages => ["unknown"]))

    visit basic_preferences_path

    assert_select "Preferred Language", :selected => "English"
  end

  test "flash message shows in original language" do
    sign_in_as(create(:user))

    visit basic_preferences_path
    click_on "Update Preferences"

    assert_content "Preferences updated"
  end

  test "flash message shows in new language" do
    sign_in_as(create(:user))

    visit basic_preferences_path
    select "français", :from => "Preferred Language"
    click_on "Update Preferences"

    assert_content "Préférences mises à jour"
  end

  test "flash message shows in new language on advanced page" do
    sign_in_as(create(:user))

    visit advanced_preferences_path
    fill_in "Preferred Languages", :with => "fr"
    click_on "Update Preferences"

    assert_content "Préférences mises à jour"
  end
end

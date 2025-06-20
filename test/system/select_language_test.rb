require "application_system_test_case"

class SelectLanguageTest < ApplicationSystemTestCase
  test "can select language when logged out" do
    visit help_path

    within_content_heading do
      assert_text "Getting Help"
      assert_no_text "Obtenir de l’aide"
    end

    click_on "Select Language"
    click_on "français"

    within_content_heading do
      assert_no_text "Getting Help"
      assert_text "Obtenir de l’aide"
    end
  end
end

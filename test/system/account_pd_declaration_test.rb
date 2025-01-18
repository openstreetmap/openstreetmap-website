require "application_system_test_case"

class AccountPdDeclarationTest < ApplicationSystemTestCase
  def setup
    @user = create(:user, :display_name => "test user")
    sign_in_as(@user)
  end

  test "can decline declaration if no declaration was made" do
    visit account_pd_declaration_path

    within_content_body do
      assert_unchecked_field "I consider my contributions to be in the Public Domain"
      assert_button "Confirm"

      click_on "Confirm"

      assert_no_text "You have also declared that you consider your edits to be in the Public Domain."
    end
  end

  test "can confirm declaration if no declaration was made" do
    visit account_pd_declaration_path

    within_content_body do
      assert_unchecked_field "I consider my contributions to be in the Public Domain"
      assert_button "Confirm"

      check "I consider my contributions to be in the Public Domain"
      click_on "Confirm"

      assert_text "You have also declared that you consider your edits to be in the Public Domain."
    end
  end

  test "show disabled checkbox if declaration was made" do
    @user.update(:consider_pd => true)

    visit account_pd_declaration_path

    within_content_body do
      assert_checked_field "I consider my contributions to be in the Public Domain", :disabled => true
      assert_button "Confirm", :disabled => true
    end
  end
end

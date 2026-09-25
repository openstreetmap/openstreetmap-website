# frozen_string_literal: true

require "application_system_test_case"

class AccountRenameTest < ApplicationSystemTestCase
  test "renaming to invalid name shouldn't alter user button" do
    user = create(:user, :display_name => "Valid User")
    sign_in_as(user)

    visit account_path

    assert_button "Valid User"
    assert_field "Display Name", :with => "Valid User"

    fill_in "Display Name", :with => "x"
    click_on "Save Changes"

    assert_button "Valid User"
    assert_field "Display Name", :with => "x"
  end
end

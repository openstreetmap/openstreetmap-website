# frozen_string_literal: true

require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  js_test "all users can be selected" do
    sign_in_as(create(:administrator_user))
    create_list(:user, 100)

    visit users_list_path

    assert_css "tbody input[type=checkbox]:checked", :count => 0
    assert_css "tbody input[type=checkbox]:not(:checked)", :count => 50
    check "user_all"
    assert_css "tbody input[type=checkbox]:checked", :count => 50
    assert_css "tbody input[type=checkbox]:not(:checked)", :count => 0

    click_on "Older Users", :match => :first

    assert_css "tbody input[type=checkbox]:checked", :count => 0
    assert_css "tbody input[type=checkbox]:not(:checked)", :count => 50
    check "user_all"
    assert_css "tbody input[type=checkbox]:checked", :count => 50
    assert_css "tbody input[type=checkbox]:not(:checked)", :count => 0
  end
end

require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  def setup
    admin = create(:administrator_user)
    sign_in_as(admin)
  end

  test "all users can be selected" do
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

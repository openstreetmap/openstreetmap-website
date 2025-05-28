require "application_system_test_case"

class UserSocialLinksTest < ApplicationSystemTestCase
  def setup
    stub_request(:get, /.*gravatar.com.*d=404/).to_return(:status => 404)

    @user = create(:user)
    sign_in_as(@user)
    visit user_path(@user)
  end

  test "can add social links" do
    within_content_body do
      click_on "Edit Profile"

      assert_no_field "Social Profile Link 1"

      click_on "Add Social Link"
      fill_in "Social Profile Link 1", :with => "https://example.com/user/fred"
      click_on "Update Profile"

      assert_link "example.com/user/fred"
    end
  end
end

require "application_system_test_case"

class UserLocationChangeTest < ApplicationSystemTestCase
  def setup
    stub_request(:get, /.*gravatar.com.*d=404/).to_return(:status => 404)
  end

  test "User can change their location" do
    user = create(:user)
    sign_in_as(user)

    visit user_path(user)

    within_content_heading do
      assert_no_selector ".bi.bi-geo-alt-fill"
    end

    visit profile_description_path

    fill_in "Home location name", :with => "Test Location"
    click_on "Update Profile"

    assert_text "Profile updated"
    within_content_heading do
      assert_text "Test Location"
    end
  end
end

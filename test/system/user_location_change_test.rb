require "application_system_test_case"

class UserLocationChangeTest < ApplicationSystemTestCase
  def setup
    stub_request(:get, /.*gravatar.com.*d=404/).to_return(:status => 404)
  end

  test "User can change their location" do
    user = create(:user)
    sign_in_as(user)

    visit user_path(user)

    within_content_body do
      assert_no_text :all, "Home location"
    end

    within_content_body do
      click_on "Edit Profile"
    end
    within_content_heading do
      click_on "Location"
    end

    within_content_body do
      fill_in "Home Location Name", :with => "Test Place"
      click_on "Update Profile"
    end

    assert_text "Profile updated."

    within_content_body do
      assert_text :all, "Home location Test Place"
    end
  end
end

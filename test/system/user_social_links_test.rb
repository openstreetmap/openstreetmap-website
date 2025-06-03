require "application_system_test_case"

class UserSocialLinksTest < ApplicationSystemTestCase
  def setup
    stub_request(:get, /.*gravatar.com.*d=404/).to_return(:status => 404)

    @user = create(:user)
    sign_in_as(@user)
    visit profile_links_path
  end

  test "can add and remove social link without submitting" do
    within_content_body do
      assert_no_field "Social Profile Link 1"

      click_on "Add Social Link"

      assert_field "Social Profile Link 1"

      click_on "Remove Social Profile Link 1"

      assert_no_field "Social Profile Link 1"
    end
  end

  test "can add and remove social links" do
    within_content_body do
      assert_no_field "Social Profile Link 1"

      click_on "Add Social Link"
      fill_in "Social Profile Link 1", :with => "https://example.com/user/fred"
      click_on "Update Profile"

      assert_link "example.com/user/fred"

      click_on "Edit Profile"
    end

    within_content_heading do
      click_on "Links"
    end

    within_content_body do
      click_on "Remove Social Profile Link 1"

      assert_no_field "Social Profile Link 1"

      click_on "Update Profile"

      assert_no_link "example.com/user/fred"
    end
  end

  test "can control social links using keyboard without submitting" do
    within_content_body do
      click_on "Add Social Link"

      assert_field "Social Profile Link 1"

      send_keys :tab, :enter

      assert_no_field "Social Profile Link 1"
    end
  end

  test "can control social links using keyboard" do
    within_content_body do
      click_on "Add Social Link"
      send_keys "https://example.com/user/typed"
      click_on "Update Profile"

      assert_link "example.com/user/typed"

      click_on "Edit Profile"
    end

    within_content_heading do
      click_on "Links"
    end

    within_content_body do
      find_field("Social Profile Link 1").click
      send_keys :tab, :enter

      assert_no_field "Social Profile Link 1"

      click_on "Update Profile"

      assert_no_link "example.com/user/typed"
    end
  end

  test "can add and remove multiple links" do
    within_content_body do
      click_on "Add Social Link"
      fill_in "Social Profile Link 1", :with => "https://example.com/a"
      click_on "Add Social Link"
      fill_in "Social Profile Link 2", :with => "https://example.com/b"
      click_on "Add Social Link"
      fill_in "Social Profile Link 3", :with => "https://example.com/c"
      click_on "Update Profile"

      assert_link "example.com/a"
      assert_link "example.com/b"
      assert_link "example.com/c"

      click_on "Edit Profile"
    end

    within_content_heading do
      click_on "Links"
    end

    within_content_body do
      assert_field "Social Profile Link 1", :with => "https://example.com/a"
      assert_field "Social Profile Link 2", :with => "https://example.com/b"
      assert_field "Social Profile Link 3", :with => "https://example.com/c"

      click_on "Remove Social Profile Link 2"

      assert_field "Social Profile Link 1", :with => "https://example.com/a"
      assert_field "Social Profile Link 2", :with => "https://example.com/c"

      click_on "Add Social Link"
      fill_in "Social Profile Link 3", :with => "https://example.com/d"
      click_on "Update Profile"

      assert_link "example.com/a"
      assert_no_link "example.com/b"
      assert_link "example.com/c"
      assert_link "example.com/d"
    end
  end
end

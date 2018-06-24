require "test_helper"

class UserMembershipTest < ActionDispatch::IntegrationTest
  include Rails::Dom::Testing::Assertions::SelectorAssertions

  def setup
    stub_hostip_requests
  end

  test "grant" do
    test_osmf_membership_display
  end

  private

  def test_osmf_membership_display
    user = create(:OSMF_member_user, :active)

    # check that badge is not shown on user page by default
    get "/user/#{ERB::Util.u(user.display_name)}/"
    assert_select "div#userinformation > div > h1 > picture > img#badge-membership-OSMF", false

    # enable "show" of the OSMF membership, test that checkbox is shown
    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    post "/login", :params => { "username" => user.email, "password" => "test", :referer => "/" }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    post "/user/#{ERB::Util.u(user.display_name)}/account/", :params => { "user[membership_OSMF]" => "1", :user => user.attributes, "user[languages]" => "" }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row > input#membership_OSMF[checked=?]", "checked"

    # check that badge is shown on user page
    get "/user/#{ERB::Util.u(user.display_name)}/"
    assert_select "div#userinformation > div > h1 > picture > img#badge-membership-OSMF"

    reset!

    user = create(:user, :active)

    # make sure that non member does not get the checkbox and post has no effect
    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    post "/login", :params => { "username" => user.email, "password" => "test", :referer => "/" }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    post "/user/#{ERB::Util.u(user.display_name)}/account/", :params => { "user[membership_OSMF]" => "1", :user => user.attributes, "user[languages]" => "" }
    assert_response :success
    assert_template :account
    assert_select "form#accountForm > fieldset > div.form-row > input#membership_OSMF", false

    # check that badge is not shown on user page
    get "/user/#{ERB::Util.u(user.display_name)}/"
    assert_select "div#userinformation > div > h1 > picture > img#badge-membership-OSMF", false
  end
end

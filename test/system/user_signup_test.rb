require "application_system_test_case"

class UserSignupTest < ApplicationSystemTestCase
  include ActionMailer::TestHelper

  def setup
    stub_request(:get, /.*gravatar.com.*d=404/).to_return(:status => 404)
  end

  test "Sign up with confirmation email" do
    visit root_path

    click_on "Sign Up"

    within_content_body do
      fill_in "Email", :with => "new_user_account@example.com"
      fill_in "Display Name", :with => "new_user_account"
      fill_in "Password", :with => "new_user_password"
      fill_in "Confirm Password", :with => "new_user_password"

      assert_emails 1 do
        click_on "Sign Up"

        assert_content "We sent you a confirmation email"
      end
    end

    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal "new_user_account@example.com", email.to.first
    email_text = email.parts[0].parts[0].decoded
    match = %r{/user/new_user_account/confirm\?confirm_string=\S+}.match(email_text)
    assert_not_nil match

    visit match[0]

    assert_content "new_user_account"
    assert_content "Welcome!"
  end

  test "Sign up with confirmation email resending" do
    visit root_path

    click_on "Sign Up"

    within_content_body do
      fill_in "Email", :with => "new_user_account@example.com"
      fill_in "Display Name", :with => "new_user_account"
      fill_in "Password", :with => "new_user_password"
      fill_in "Confirm Password", :with => "new_user_password"

      assert_emails 2 do
        click_on "Sign Up"

        assert_content "We sent you a confirmation email"

        click_on "Resend the confirmation email"

        assert_content "Email Address or Username"
      end
    end

    assert_content "sent a new confirmation"
    assert_no_content "<p>"

    email = ActionMailer::Base.deliveries.last
    assert_equal 1, email.to.count
    assert_equal "new_user_account@example.com", email.to.first
    email_text = email.parts[0].parts[0].decoded
    match = %r{/user/new_user_account/confirm\?confirm_string=\S+}.match(email_text)
    assert_not_nil match

    visit match[0]

    assert_content "new_user_account"
    assert_content "Welcome!"
  end

  test "Sign up from login page" do
    visit login_path

    within_content_heading do
      click_on "Sign Up"
    end

    within_content_body do
      assert_content "Confirm Password"
    end
  end

  test "Show OpenID form when OpenID provider button is clicked" do
    visit login_path

    within_content_body do
      assert_no_field "OpenID URL"
      assert_no_button "Continue"

      click_on "Log in with OpenID"

      assert_field "OpenID URL"
      assert_button "Continue"
    end
  end
end

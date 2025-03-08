require "application_system_test_case"

class UserEmailChangeTest < ApplicationSystemTestCase
  include ActionMailer::TestHelper

  def setup
    stub_request(:get, /.*gravatar.com.*d=404/).to_return(:status => 404)
  end

  test "User can change their email address" do
    user = create(:user)
    sign_in_as(user)

    assert_emails 1 do
      visit account_path
      fill_in "New Email Address", :with => "new_tester@example.com"
      click_on "Save Changes"
      assert_equal "new_tester@example.com", user.reload.new_email
    end

    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal "new_tester@example.com", email.to.first
    assert_match %r{/user/confirm-email\?confirm_string=[A-Za-z0-9\-_%]+\s}, email.parts[0].parts[0].decoded

    if email.parts[0].parts[0].decoded =~ %r{(/user/confirm-email\?confirm_string=[A-Za-z0-9\-_%]+)\s}
      visit Regexp.last_match(1)
      assert page.has_css?("body.accounts-show")
    end

    assert_equal "new_tester@example.com", user.reload.email
  end
end

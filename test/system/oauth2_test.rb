require "application_system_test_case"

class Oauth2Test < ApplicationSystemTestCase
  def test_authorized_applications
    sign_in_as(create(:user))
    visit oauth_authorized_applications_path

    assert_text "OpenStreetMap Web Site"

    accept_alert do
      click_on "Revoke Access"
    end

    assert_text "You have not yet authorized any OAuth 2 applications."
  end
end

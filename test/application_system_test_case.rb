# frozen_string_literal: true

require "test_helper"

ENV.delete("http_proxy")

ActiveSupport.on_load(:action_dispatch_system_test_case) do
  ActionDispatch::SystemTesting::Server.silence_puma = true
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include ActionMailer::TestCase::ClearTestDeliveries

  Capybara.configure do |config|
    config.enable_aria_label = true
  end

  if ENV["CAPYBARA_SERVER_PORT"]
    served_by :host => "rails-app", :port => ENV["CAPYBARA_SERVER_PORT"]

    driven_by(
      :selenium,
      :using => Settings.system_test_headless ? :headless_firefox : :firefox,
      :options => {
        :url => "http://#{ENV.fetch('SELENIUM_HOST', nil)}:4444",
        :browser => :remote
      }
    ) do |options|
      options.add_preference("intl.accept_languages", "en")
      options.binary = Settings.system_test_firefox_binary if Settings.system_test_firefox_binary
    end
  else
    driven_by :selenium, :using => Settings.system_test_headless ? :headless_firefox : :firefox do |options|
      options.add_preference("intl.accept_languages", "en")
      options.binary = Settings.system_test_firefox_binary if Settings.system_test_firefox_binary
    end
  end

  def before_setup
    super
    osm_website_app = create(:oauth_application, :name => "OpenStreetMap Web Site", :scopes => "write_api write_notes")
    Settings.oauth_application = osm_website_app.uid
  end

  def after_teardown
    Settings.reload!
    super
  end

  private

  def sign_in_as(user)
    visit login_path
    within "form", :text => "Email Address or Username" do
      fill_in "username", :with => user.email
      fill_in "password", :with => "s3cr3t"
      click_on "Log in"
    end
  end

  def sign_out
    visit logout_path
    click_on "Logout", :match => :first
  end

  def within_sidebar(&)
    within("#sidebar_content", &)
  end

  def within_content_body(&)
    within("#content > .content-body", &)
  end

  def within_content_heading(&)
    within("#content > .content-heading", &)
  end
end

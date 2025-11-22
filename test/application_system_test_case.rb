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

  cattr_accessor(:capybara_server_port) { ENV.fetch("CAPYBARA_SERVER_PORT", nil) }

  served_by :host => "rails-app", :port => capybara_server_port if capybara_server_port

  def self.driven_by_selenium(config_name = "default", opts = {})
    preferences = opts.fetch(:preferences, {}).reverse_merge(
      "intl.accept_languages" => "en"
    )

    options = {
      :name => config_name
    }

    if capybara_server_port
      selenium_host = "http://selenium-#{config_name}:4444"
      options = options.merge(
        :url => selenium_host,
        :browser => :remote
      )
    end

    driven_by(
      :selenium,
      :using => Settings.system_test_headless ? :headless_firefox : :firefox,
      :options => options
    ) do |options|
      preferences.each do |name, value|
        options.add_preference(name, value)
      end
      options.binary = Settings.system_test_firefox_binary if Settings.system_test_firefox_binary
    end
  end

  driven_by_selenium

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

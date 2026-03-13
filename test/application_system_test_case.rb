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

  def self.register_selenium_driver(config_name = "default", opts = {})
    preferences = opts.fetch(:preferences, {}).reverse_merge(
      "intl.accept_languages" => "en"
    )

    headless = Settings.system_test_headless
    driver_name = :"selenium_#{config_name}"

    driver_options = { :browser => :firefox }

    if capybara_server_port
      selenium_host = "http://selenium-#{config_name}:4444"
      driver_options = driver_options.merge(
        :url => selenium_host,
        :browser => :remote
      )
    end

    Capybara.register_driver driver_name do |app|
      options = Selenium::WebDriver::Firefox::Options.new
      options.add_argument("-headless") if headless
      preferences.each do |name, value|
        options.add_preference(name, value)
      end
      options.binary = Settings.system_test_firefox_binary if Settings.system_test_firefox_binary

      Capybara::Selenium::Driver.new(app, **driver_options, :options => options)
    end

    driver_name
  end

  # Define a test that uses a full browser via Selenium, for use in test
  # classes that default to rack_test but have individual tests needing
  # JavaScript. Note: js_test blocks get a separate browser session, so
  # you must call sign_in_as within the block if authentication is needed.
  #
  # Pass driver_opts to customize the Selenium driver, e.g. to set
  # browser language preferences:
  #   js_test "name", :driver => "de", :preferences => { "intl.accept_languages" => "de" }
  def self.js_test(name, driver_opts = {}, &block)
    config_name = driver_opts.delete(:driver) || "default"
    driver = register_selenium_driver(config_name, driver_opts)
    test(name) do
      Capybara.using_driver(driver) do
        instance_exec(&block)
      end
    end
  end

  driven_by :rack_test

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

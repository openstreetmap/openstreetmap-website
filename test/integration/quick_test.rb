# frozen_string_literal: true

require "test_helper"

class QuickTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # Test the creation of a diary entry, making sure that you are redirected to
  # login page when not logged in
  def test_unauthenticated
    cookies["_osm_session"] = "ok"
    get "/notifications"
    assert_redirected_to login_path(:referer => "/notifications")
    follow_redirect!
    assert_response :success
  end

  def test_authenticated
    cookies["_osm_session"] = "ok"
    sign_in create(:user)
    get "/notifications"
    assert_response :success
  end
end

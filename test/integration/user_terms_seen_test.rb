require File.dirname(__FILE__) + '/../test_helper'

class UserTermsSeenTest < ActionController::IntegrationTest
  fixtures :users

  def auth_header(user, pass)
    {"HTTP_AUTHORIZATION" => "Basic %s" % Base64.encode64("#{user}:#{pass}")}
  end

  def test_api_blocked
    user = users(:terms_not_seen_user)

    get "/api/#{API_VERSION}/user/details", nil, auth_header(user.display_name, "test")
    assert_response :forbidden

    # touch it so that the user has seen the terms
    user.terms_seen = true
    user.save

    get "/api/#{API_VERSION}/user/details", nil, auth_header(user.display_name, "test")
    assert_response :success
  end

  def test_terms_presented_at_login
    user = users(:terms_not_seen_user)

    # try to log in
    get_via_redirect "/login"
    assert_response :success
    assert_template 'user/login'
    post "/login", {'user[email]' => user.email, 'user[password]' => 'test', :referer => "/"}
    assert_response :redirect
    # but now we need to look at the terms
    assert_redirected_to "controller" => "user", "action" => "terms", :referer => "/"
    follow_redirect!
    assert_response :success

    # don't agree to the terms, but hit decline
    
    # should be carried through to a normal login
  end

end

    

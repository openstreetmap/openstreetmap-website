require File.dirname(__FILE__) + '/../test_helper'

class UserLoginTest < ActionController::IntegrationTest
  fixtures :users

  def setup
    openid_setup
  end

  def test_login_password_success
    user = users(:normal_user)

    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    post '/login', {'username' => user.email, 'password' => "test", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'changeset/list'
  end

  def test_login_password_fail
    user = users(:normal_user)

    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    post '/login', {'username' => user.email, 'password' => "wrong", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'
  end

  def test_login_openid_success
    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    post '/login', {'openid_url' => "http://localhost:1123/john.doe?openid.success=true", :referer => "/browse"}
    assert_response :redirect

    res = openid_request(@response.redirect_url)
    res2 = post '/login', res

    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'changeset/list'
  end

  def test_login_openid_cancel
    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    post '/login', {'openid_url' => "http://localhost:1123/john.doe", :referer => "/diary"}
    assert_response :redirect

    res = openid_request(@response.redirect_url)
    post '/login', res

    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'
  end

  def test_login_openid_invalid_provider
    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    #Use a different port that doesn't have the OpenID provider running on to test an invalid openID
    post '/login', {'openid_url' => "http://localhost:1124/john.doe", :referer => "/diary"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'
  end

  def test_login_openid_invalid_url
    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    #Use a url with an invalid protocol to make sure it handles that correctly too
    post '/login', {'openid_url' => "htt://localhost:1123/john.doe", :referer => "/diary"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'
  end

  def test_login_openid_unknown
    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    post '/login', {'openid_url' => "http://localhost:1123/john.doe?openid.success=true_somethingelse", :referer => "/diary"}
    assert_response :redirect

    res = openid_request(@response.redirect_url)
    res2 = post '/login', res

    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'user/new'
  end
end

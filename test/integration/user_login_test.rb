require File.dirname(__FILE__) + '/../test_helper'

class UserLoginTest < ActionDispatch::IntegrationTest
  fixtures :users

  def setup
    openid_setup
  end

  def test_login_email_password_normal
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

    post '/login', {'username' => user.email, 'password' => "test", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'changeset/list'
  end

  def test_login_email_password_normal_upcase
    user = users(:normal_user)

    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post '/login', {'username' => user.email.upcase, 'password' => "wrong", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'

    post '/login', {'username' => user.email.upcase, 'password' => "test", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'
  end

  def test_login_email_password_normal_titlecase
    user = users(:normal_user)

    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post '/login', {'username' => user.email.titlecase, 'password' => "wrong", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'

    post '/login', {'username' => user.email.titlecase, 'password' => "test", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'
  end

  def test_login_email_password_public
    user = users(:public_user)

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

    post '/login', {'username' => user.email, 'password' => "test", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'changeset/list'
  end

  def test_login_email_password_public_upcase
    user = users(:public_user)

    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post '/login', {'username' => user.email.upcase, 'password' => "wrong", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'

    post '/login', {'username' => user.email.upcase, 'password' => "test", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'changeset/list'
  end

  def test_login_email_password_public_titlecase
    user = users(:public_user)

    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post '/login', {'username' => user.email.titlecase, 'password' => "wrong", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'

    post '/login', {'username' => user.email.titlecase, 'password' => "test", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'changeset/list'
  end

  def test_login_username_password_normal
    user = users(:normal_user)

    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post '/login', {'username' => user.display_name, 'password' => "wrong", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'

    post '/login', {'username' => user.display_name, 'password' => "test", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'changeset/list'
  end

  def test_login_username_password_normal_upcase
    user = users(:normal_user)

    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post '/login', {'username' => user.display_name.upcase, 'password' => "wrong", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'

    post '/login', {'username' => user.display_name.upcase, 'password' => "test", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'
  end

  def test_login_username_password_normal_titlecase
    user = users(:normal_user)

    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post '/login', {'username' => user.display_name.titlecase, 'password' => "wrong", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'

    post '/login', {'username' => user.display_name.titlecase, 'password' => "test", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'
  end

  def test_login_username_password_public
    user = users(:public_user)

    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post '/login', {'username' => user.display_name, 'password' => "wrong", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'

    post '/login', {'username' => user.display_name, 'password' => "test", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'changeset/list'
  end

  def test_login_username_password_public_upcase
    user = users(:public_user)

    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post '/login', {'username' => user.display_name.upcase, 'password' => "wrong", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'

    post '/login', {'username' => user.display_name.upcase, 'password' => "test", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'changeset/list'
  end

  def test_login_username_password_public_titlecase
    user = users(:public_user)

    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post '/login', {'username' => user.display_name.titlecase, 'password' => "wrong", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'login'

    post '/login', {'username' => user.display_name.titlecase, 'password' => "test", :referer => "/browse"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'changeset/list'
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

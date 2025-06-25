require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/login", :method => :get },
      { :controller => "sessions", :action => "new" }
    )
    assert_routing(
      { :path => "/login", :method => :post },
      { :controller => "sessions", :action => "create" }
    )
    assert_recognizes(
      { :controller => "sessions", :action => "new", :format => "html" },
      { :path => "/login.html", :method => :get }
    )

    assert_routing(
      { :path => "/logout", :method => :get },
      { :controller => "sessions", :action => "destroy" }
    )
    assert_routing(
      { :path => "/logout", :method => :post },
      { :controller => "sessions", :action => "destroy" }
    )
    assert_recognizes(
      { :controller => "sessions", :action => "destroy", :format => "html" },
      { :path => "/logout.html", :method => :get }
    )
  end

  def test_login
    user = create(:user)

    get login_path
    assert_redirected_to login_path(:cookie_test => true)
    follow_redirect!
    assert_response :success
    assert_template "sessions/new"

    get login_path, :params => { :username => user.display_name, :password => "test" }
    assert_response :success
    assert_template "sessions/new"

    post login_path, :params => { :username => user.display_name, :password => "test" }
    assert_redirected_to root_path

    post login_path, :params => { :username => " #{user.display_name}", :password => "test" }
    assert_redirected_to root_path

    post login_path, :params => { :username => "#{user.display_name} ", :password => "test" }
    assert_redirected_to root_path
  end

  def test_login_remembered
    user = create(:user)

    post login_path, :params => { :username => user.display_name, :password => "test", :remember_me => "yes" }
    assert_redirected_to root_path

    assert_equal 28 * 86400, session[:_remember_for]
  end

  def test_login_not_remembered
    user = create(:user)

    post login_path, :params => { :username => user.display_name, :password => "test", :remember_me => "0" }
    assert_redirected_to root_path

    assert_nil session[:_remember_for]
  end

  def test_logout_without_referer
    post logout_path
    assert_redirected_to root_path
  end

  def test_logout_with_referer
    post logout_path, :params => { :referer => "/test" }
    assert_redirected_to "/test"
  end

  def test_logout_fallback_without_referer
    get logout_path
    assert_response :success
    assert_template "sessions/destroy"
    assert_select "input[name=referer]:not([value])"
  end

  def test_logout_fallback_with_referer
    get logout_path, :params => { :referer => "/test" }
    assert_response :success
    assert_template "sessions/destroy"
    assert_select "input[name=referer][value=?]", "/test"
  end
end

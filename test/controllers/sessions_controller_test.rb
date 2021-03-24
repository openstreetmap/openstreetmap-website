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
    assert_response :redirect
    assert_redirected_to login_path(:cookie_test => true)
    follow_redirect!
    assert_response :success
    assert_template "sessions/new"

    get login_path, :params => { :username => user.display_name, :password => "test" }
    assert_response :success
    assert_template "sessions/new"

    post login_path, :params => { :username => user.display_name, :password => "test" }
    assert_response :redirect
    assert_redirected_to root_path
  end

  def test_logout_without_referer
    post logout_path
    assert_response :redirect
    assert_redirected_to root_path
  end

  def test_logout_with_referer
    post logout_path, :params => { :referer => "/test" }
    assert_response :redirect
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

  def test_logout_removes_session_token
    user = build(:user, :pending)
    post user_new_path, :params => { :user => user.attributes }
    post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }

    assert_difference "User.find_by(:email => user.email).tokens.count", -1 do
      post logout_path
    end
    assert_response :redirect
    assert_redirected_to root_path
  end
end

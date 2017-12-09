require "test_helper"

class OauthControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/oauth/revoke", :method => :get },
      { :controller => "oauth", :action => "revoke" }
    )
    assert_routing(
      { :path => "/oauth/revoke", :method => :post },
      { :controller => "oauth", :action => "revoke" }
    )
    assert_routing(
      { :path => "/oauth/authorize", :method => :get },
      { :controller => "oauth", :action => "authorize" }
    )
    assert_routing(
      { :path => "/oauth/authorize", :method => :post },
      { :controller => "oauth", :action => "authorize" }
    )
    assert_routing(
      { :path => "/oauth/token", :method => :get },
      { :controller => "oauth", :action => "token" }
    )
    assert_routing(
      { :path => "/oauth/request_token", :method => :get },
      { :controller => "oauth", :action => "request_token" }
    )
    assert_routing(
      { :path => "/oauth/request_token", :method => :post },
      { :controller => "oauth", :action => "request_token" }
    )
    assert_routing(
      { :path => "/oauth/access_token", :method => :get },
      { :controller => "oauth", :action => "access_token" }
    )
    assert_routing(
      { :path => "/oauth/access_token", :method => :post },
      { :controller => "oauth", :action => "access_token" }
    )
    assert_routing(
      { :path => "/oauth/test_request", :method => :get },
      { :controller => "oauth", :action => "test_request" }
    )
  end

  ##
  # test revoking a specific token
  def test_revoke_by_token
    user = create(:user)
    applications = create_list(:client_application, 2, :user => user)
    tokens = create_list(:oauth_token, 2, :user => user, :client_application => applications.first, :authorized_at => Time.now.utc)
    create_list(:oauth_token, 2, :user => user, :client_application => applications.second, :authorized_at => Time.now.utc)

    assert_no_difference "OauthToken.authorized.count" do
      post :revoke, :token => tokens.first.token
      assert_response :forbidden
    end

    assert_no_difference "OauthToken.authorized.count" do
      post :revoke, { :token => "dummy" }, { :user => user }
      assert_response :not_found
    end

    assert_difference "OauthToken.authorized.count", -1 do
      post :revoke, { :token => tokens.first.token }, { :user => user }
      assert_response :redirect
      assert_redirected_to oauth_clients_url(:display_name => user.display_name)
      assert tokens.first.reload.invalidated?
      assert !tokens.second.reload.invalidated?
    end
  end

  ##
  # test revoking all tokens for an application
  def text_revoke_by_application
    user = create(:user)
    applications = create_list(:client_application, 2, :user => user)
    tokens = create_list(:oauth_token, 2, :user => user, :client_application => applications.first, :authorized_at => Time.now.utc)
    create_list(:oauth_token, 2, :user => user, :client_application => applications.second, :authorized_at => Time.now.utc)

    assert_no_difference "OauthToken.authorized.count" do
      post :revoke, :application => applications.first.id
      assert_response :forbidden
    end

    assert_no_difference "OauthToken.authorized.count" do
      post :revoke, { :application => 0 }, { :user => user }
      assert_response :not_found
    end

    assert_difference "OauthToken.authorized.count", -2 do
      post :revoke, { :application => applications.first.id }, { :user => user }
      assert_response :redirect
      assert_redirected_to oauth_clients_url(:display_name => user.display_name)
      assert tokens.first.reload.invalidated?
      assert tokens.second.reload.invalidated?
    end
  end
end

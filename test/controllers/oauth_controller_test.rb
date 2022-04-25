require "test_helper"

class OauthControllerTest < ActionDispatch::IntegrationTest
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
end

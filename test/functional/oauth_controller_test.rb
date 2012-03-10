require File.dirname(__FILE__) + '/../test_helper'

class OauthControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/oauth/revoke" },
      { :controller => "oauth", :action => "revoke" }
    )
    assert_routing(
      { :path => "/oauth/authorize" },
      { :controller => "oauth", :action => "authorize" }
    )
    assert_routing(
      { :path => "/oauth/token" },
      { :controller => "oauth", :action => "token" }
    )
    assert_routing(
      { :path => "/oauth/request_token" },
      { :controller => "oauth", :action => "request_token" }
    )
    assert_routing(
      { :path => "/oauth/access_token" },
      { :controller => "oauth", :action => "access_token" }
    )
    assert_routing(
      { :path => "/oauth/test_request" },
      { :controller => "oauth", :action => "test_request" }
    )
  end
end

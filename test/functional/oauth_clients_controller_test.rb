require File.dirname(__FILE__) + '/../test_helper'

class OauthClientsControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/username/oauth_clients", :method => :get },
      { :controller => "oauth_clients", :action => "index", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/oauth_clients/new", :method => :get },
      { :controller => "oauth_clients", :action => "new", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/oauth_clients", :method => :post },
      { :controller => "oauth_clients", :action => "create", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/oauth_clients/1", :method => :get },
      { :controller => "oauth_clients", :action => "show", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/oauth_clients/1/edit", :method => :get },
      { :controller => "oauth_clients", :action => "edit", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/oauth_clients/1", :method => :put },
      { :controller => "oauth_clients", :action => "update", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/oauth_clients/1", :method => :delete },
      { :controller => "oauth_clients", :action => "destroy", :display_name => "username", :id => "1" }
    )
  end
end

require File.dirname(__FILE__) + '/../test_helper'

class UserRolesControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/username/role/rolename/grant", :method => :post },
      { :controller => "user_roles", :action => "grant", :display_name => "username", :role => "rolename" }
    )
    assert_routing(
      { :path => "/user/username/role/rolename/revoke", :method => :post },
      { :controller => "user_roles", :action => "revoke", :display_name => "username", :role => "rolename" }
    )
  end
end

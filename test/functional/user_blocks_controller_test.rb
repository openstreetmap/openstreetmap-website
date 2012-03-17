require File.dirname(__FILE__) + '/../test_helper'

class UserBlocksControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/blocks/new/username", :method => :get },
      { :controller => "user_blocks", :action => "new", :display_name => "username" }
    )

    assert_routing(
      { :path => "/user_blocks", :method => :get },
      { :controller => "user_blocks", :action => "index" }
    )
    assert_routing(
      { :path => "/user_blocks/new", :method => :get },
      { :controller => "user_blocks", :action => "new" }
    )
    assert_routing(
      { :path => "/user_blocks", :method => :post },
      { :controller => "user_blocks", :action => "create" }
    )
    assert_routing(
      { :path => "/user_blocks/1", :method => :get },
      { :controller => "user_blocks", :action => "show", :id => "1" }
    )
    assert_routing(
      { :path => "/user_blocks/1/edit", :method => :get },
      { :controller => "user_blocks", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/user_blocks/1", :method => :put },
      { :controller => "user_blocks", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/user_blocks/1", :method => :delete },
      { :controller => "user_blocks", :action => "destroy", :id => "1" }
    )
    assert_routing(
      { :path => "/blocks/1/revoke", :method => :get },
      { :controller => "user_blocks", :action => "revoke", :id => "1" }
    )
    assert_routing(
      { :path => "/blocks/1/revoke", :method => :post },
      { :controller => "user_blocks", :action => "revoke", :id => "1" }
    )

    assert_routing(
      { :path => "/user/username/blocks", :method => :get },
      { :controller => "user_blocks", :action => "blocks_on", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/blocks_by", :method => :get },
      { :controller => "user_blocks", :action => "blocks_by", :display_name => "username" }
    )
  end
end

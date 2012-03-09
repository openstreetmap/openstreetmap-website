require File.dirname(__FILE__) + '/../test_helper'
require 'message_controller'

class MessageControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/username/inbox", :method => :get },
      { :controller => "message", :action => "inbox", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/outbox", :method => :get },
      { :controller => "message", :action => "outbox", :display_name => "username" }
    )
    assert_routing(
      { :path => "/message/new/username", :method => :get },
      { :controller => "message", :action => "new", :display_name => "username" }
    )
    assert_routing(
      { :path => "/message/new/username", :method => :post },
      { :controller => "message", :action => "new", :display_name => "username" }
    )
    assert_routing(
      { :path => "/message/read/1", :method => :get },
      { :controller => "message", :action => "read", :message_id => "1" }
    )
    assert_routing(
      { :path => "/message/mark/1", :method => :post },
      { :controller => "message", :action => "mark", :message_id => "1" }
    )
    assert_routing(
      { :path => "/message/reply/1", :method => :get },
      { :controller => "message", :action => "reply", :message_id => "1" }
    )
    assert_routing(
      { :path => "/message/delete/1", :method => :post },
      { :controller => "message", :action => "delete", :message_id => "1" }
    )
  end
end

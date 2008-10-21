require File.dirname(__FILE__) + '/../test_helper'
require 'browse_controller'

# Re-raise errors caught by the controller.
class BrowseController; def rescue_action(e) raise e end; end

  class BrowseControllerTest < Test::Unit::TestCase
  api_fixtures
  


  def setup
    @controller = BrowseController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def basic_authorization(user, pass)
    @request.env["HTTP_AUTHORIZATION"] = "Basic %s" % Base64.encode64("#{user}:#{pass}")
  end

  def content(c)
    @request.env["RAW_POST_DATA"] = c.to_s
  end

  # We need to load the home page, then activate the start rjs method
  # and finally check that the new panel has loaded.
  def test_start
  
  end
  
  # This should display the last 20 nodes that were edited.
  def test_index
    @nodes = Node.find(:all, :order => "timestamp DESC", :limit => 20)
    assert @nodes.size <= 20
    get :index
    assert_response :success
    assert_template "index"
    # Now check that all 20 (or however many were returned) nodes are in the html
    assert_select "h2", :text => "#{@nodes.size} Recently Changed Nodes", :count => 1
    assert_select "ul[id='recently_changed'] li a", :count => @nodes.size
    @nodes.each do |node|
      name = node.tags_as_hash['name'].to_s
      name = "(No name)" if name.length == 0
      assert_select "ul[id='recently_changed'] li a[href=/browse/node/#{node.id}]", :text => "#{name} - #{node.id} (#{node.version})"
    end
  end
  
  # Test reading a relation
  def test_read_relation
    
  end
  
  def test_read_relation_history
    
  end
  
  def test_read_way
    
  end
  
  def test_read_way_history
    
  end
  
  def test_read_node
    
  end
  
  def test_read_node_history
    
  end
  
  def test_read_changeset
    
  end
end

require File.dirname(__FILE__) + '/../test_helper'
require 'browse_controller'

class BrowseControllerTest < ActionController::TestCase
  api_fixtures

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

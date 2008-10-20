require File.dirname(__FILE__) + '/../test_helper'
require 'changeset_controller'

# Re-raise errors caught by the controller.
class ChangesetController; def rescue_action(e) raise e end; end

  class ChangesetControllerTest < Test::Unit::TestCase
  api_fixtures
  


  def setup
    @controller = ChangesetController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def basic_authorization(user, pass)
    @request.env["HTTP_AUTHORIZATION"] = "Basic %s" % Base64.encode64("#{user}:#{pass}")
  end

  def content(c)
    @request.env["RAW_POST_DATA"] = c.to_s
  end
  
  # -----------------------
  # Test simple changeset creation
  # -----------------------
  
  def test_create
    basic_authorization "test@openstreetmap.org", "test"
    
    # Create the first user's changeset
    content "<osm><changeset>" +
      "<tag k='created_by' v='osm test suite checking changesets'/>" + 
      "</changeset></osm>"
    put :create
    
    assert_response :success, "Creation of changeset did not return sucess status"
    newid = @response.body
  end
  
  def test_create_invalid
    basic_authorization "test@openstreetmap.org", "test"
    content "<osm><changeset></osm>"
    put :create
  end

  def test_read
    
  end
  
  def test_close
    
  end
  
  def test_upload
    
  end
  
end

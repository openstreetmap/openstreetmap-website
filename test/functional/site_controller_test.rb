require File.dirname(__FILE__) + '/../test_helper'

class SiteControllerTest < ActionController::TestCase
  ## Lets check that we can get all the pages without any errors
  
  # Get the index
  def test_index
    get :index
    assert_response :success
    assert_template 'index'
    # Seems that we need to wait for Rails 2.3 for this one
    # assert_template :partial => '_search', :count => 1
  end
  
  # Get the edit page
  def test_edit
    get :edit
    # Should be redirected
    assert_response :redirect
  end
  
  # Get the export page
  def test_export
    get :export
    assert_response :success
    assert_template 'index'
  end
  
  # Offline page
  def test_offline
    get :offline
    assert_response :success
    assert_template 'offline'
  end
end

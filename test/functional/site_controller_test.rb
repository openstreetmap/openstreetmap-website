require File.dirname(__FILE__) + '/../test_helper'

class SiteControllerTest < ActionController::TestCase
  ## Lets check that we can get all the pages without any errors
  
  # Get the index
  def test_index
    get :index
    assert_response :success
    assert_template 'index'
    assert_site_partials
  end
  
  # Get the edit page
  def test_edit
    get :edit
    # Should be redirected
    assert_redirected_to :controller => :user, :action => 'login', :referer => "/edit"
  end
  
  # Get the export page
  def test_export
    get :export
    assert_response :success
    assert_template 'index'
    assert_site_partials
  end
  
  # Offline page
  def test_offline
    get :offline
    assert_response :success
    assert_template 'offline'
    assert_site_partials 0
  end
  
  def assert_site_partials(count = 1)
    assert_template :partial => '_search', :count => count
    assert_template :partial => '_key', :count => count
    assert_template :partial => '_sidebar', :count => count
  end
end

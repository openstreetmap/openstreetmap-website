require File.dirname(__FILE__) + '/../test_helper'

class SiteControllerTest < ActionController::TestCase
  fixtures :users

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

  # test the right editor gets used when the user hasn't set a preference
  def test_edit_without_preference
    get(:edit, nil, { 'user' => users(:public_user).id })
    assert_response :success
    assert_template :partial => "_#{DEFAULT_EDITOR}", :count => 1
  end

  # and when they have...
  def test_edit_with_preference
    user = users(:public_user)
    user.preferred_editor = "potlatch"
    user.save!

    get(:edit, nil, { 'user' => user.id })
    assert_response :success
    assert_template :partial => "_potlatch", :count => 1

    user = users(:public_user)
    user.preferred_editor = "remote"
    user.save!

    get(:edit, nil, { 'user' => user.id })
    assert_response :success
    assert_template "index"
  end    
end

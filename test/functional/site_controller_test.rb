require File.dirname(__FILE__) + '/../test_helper'

class SiteControllerTest < ActionController::TestCase
  fixtures :users

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/", :method => :get },
      { :controller => "site", :action => "index" }
    )
    assert_routing(
      { :path => "/", :method => :post },
      { :controller => "site", :action => "index" }
    )
    assert_recognizes(
      { :controller => "site", :action => "index" },
      { :path => "/index.html", :method => :get }
    )
    assert_routing(
      { :path => "/edit", :method => :get },
      { :controller => "site", :action => "edit" }
    )
    assert_recognizes(
      { :controller => "site", :action => "edit", :format => "html" },
      { :path => "/edit.html", :method => :get }
    )
    assert_routing(
      { :path => "/copyright", :method => :get },
      { :controller => "site", :action => "copyright" }
    )
    assert_routing(
      { :path => "/copyright/locale", :method => :get },
      { :controller => "site", :action => "copyright", :copyright_locale => "locale" }
    )
    assert_routing(
      { :path => "/export", :method => :get },
      { :controller => "site", :action => "export" }
    )
    assert_recognizes(
      { :controller => "site", :action => "export", :format => "html" },
      { :path => "/export.html", :method => :get }
    )
    assert_routing(
      { :path => "/offline", :method => :get },
      { :controller => "site", :action => "offline" }
    )
    assert_routing(
      { :path => "/key", :method => :post },
      { :controller => "site", :action => "key" }
    )
    assert_routing(
      { :path => "/go/shortcode", :method => :get },
      { :controller => "site", :action => "permalink", :code => "shortcode" }
    )
    assert_routing(
      { :path => "/preview/formatname", :method => :get },
      { :controller => "site", :action => "preview", :format => "formatname" }
    )
  end

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
    @request.cookies["_osm_username"] = users(:public_user).display_name

    get(:edit, nil, { 'user' => users(:public_user).id })
    assert_response :success
    assert_template :partial => "_#{DEFAULT_EDITOR}", :count => 1
  end

  # and when they have...
  def test_edit_with_preference
    @request.cookies["_osm_username"] = users(:public_user).display_name

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

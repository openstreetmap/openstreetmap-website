require File.dirname(__FILE__) + '/../test_helper'

class SiteControllerTest < ActionController::TestCase
  api_fixtures

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
      { :controller => "site", :action => "index", :export => true }
    )
    assert_recognizes(
      { :controller => "site", :action => "index", :export => true, :format => "html" },
      { :path => "/export.html", :method => :get }
    )
    assert_routing(
      { :path => "/offline", :method => :get },
      { :controller => "site", :action => "offline" }
    )
    assert_routing(
      { :path => "/key", :method => :get },
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
    assert_routing(
      { :path => "/id", :method => :get },
      { :controller => "site", :action => "id" }
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

  def test_index_redirect
    get :index, :lat => 4, :lon => 5
    assert_redirected_to :controller => :site, :action => 'index', :anchor => 'map=5/4/5'

    get :index, :lat => 4, :lon => 5, :zoom => 3
    assert_redirected_to :controller => :site, :action => 'index', :anchor => 'map=3/4/5'

    get :index, :layers => 'T'
    assert_redirected_to :controller => :site, :action => 'index', :anchor => 'layers=T'

    get :index, :notes => 'yes'
    assert_redirected_to :controller => :site, :action => 'index', :anchor => 'layers=N'

    get :index, :lat => 4, :lon => 5, :zoom => 3, :layers => 'T'
    assert_redirected_to :controller => :site, :action => 'index', :anchor => 'map=3/4/5&layers=T'
  end

  def test_permalink
    get :permalink, :code => 'wBz3--'
    assert_redirected_to :controller => :site, :action => 'index', :anchor => 'map=3/4.8779296875/3.955078125'
  end

  # Get the edit page
  def test_edit
    get :edit
    # Should be redirected
    assert_redirected_to :controller => :user, :action => 'login', :referer => "/edit"
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

  def test_edit_with_node
    @request.cookies["_osm_username"] = users(:public_user).display_name

    user = users(:public_user)
    node = current_nodes(:visible_node)

    get :edit, { :node => node.id }, { 'user' => user.id }
    assert_equal 1.0, assigns(:lat)
    assert_equal 1.0, assigns(:lon)
  end

  def test_edit_with_way
    @request.cookies["_osm_username"] = users(:public_user).display_name

    user = users(:public_user)
    way  = current_ways(:visible_way)

    get :edit, { :way => way.id }, { 'user' => user.id }
    assert_equal 3.0, assigns(:lat)
    assert_equal 3.0, assigns(:lon)
  end

  def test_edit_with_gpx
    @request.cookies["_osm_username"] = users(:public_user).display_name

    user = users(:public_user)
    gpx  = gpx_files(:public_trace_file)

    get :edit, { :gpx => gpx.id }, { 'user' => user.id }
    assert_equal 1.0, assigns(:lat)
    assert_equal 1.0, assigns(:lon)
  end
end

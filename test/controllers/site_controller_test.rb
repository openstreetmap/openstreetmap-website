require "test_helper"

class SiteControllerTest < ActionController::TestCase
  ##
  # setup oauth keys
  def setup
    Object.const_set("ID_KEY", create(:client_application).key)
    Object.const_set("POTLATCH2_KEY", create(:client_application).key)

    stub_hostip_requests
  end

  ##
  # clear oauth keys
  def teardown
    Object.send("remove_const", "ID_KEY")
    Object.send("remove_const", "POTLATCH2_KEY")
  end

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
      { :path => "/welcome", :method => :get },
      { :controller => "site", :action => "welcome" }
    )
    assert_routing(
      { :path => "/fixthemap", :method => :get },
      { :controller => "site", :action => "fixthemap" }
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
      { :path => "/key", :method => :get },
      { :controller => "site", :action => "key" }
    )
    assert_routing(
      { :path => "/go/shortcode", :method => :get },
      { :controller => "site", :action => "permalink", :code => "shortcode" }
    )
    assert_routing(
      { :path => "/preview/typename", :method => :post },
      { :controller => "site", :action => "preview", :type => "typename" }
    )
    assert_routing(
      { :path => "/id", :method => :get },
      { :controller => "site", :action => "id" }
    )
  end

  # Test the index page
  def test_index
    get :index
    assert_response :success
    assert_template "index"
  end

  # Test the index page redirects
  def test_index_redirect
    get :index, :node => 123
    assert_redirected_to :controller => :browse, :action => :node, :id => 123

    get :index, :way => 123
    assert_redirected_to :controller => :browse, :action => :way, :id => 123

    get :index, :relation => 123
    assert_redirected_to :controller => :browse, :action => :relation, :id => 123

    get :index, :note => 123
    assert_redirected_to :controller => :browse, :action => :note, :id => 123

    get :index, :query => "test"
    assert_redirected_to :controller => :geocoder, :action => :search, :query => "test"

    get :index, :lat => 4, :lon => 5
    assert_redirected_to :controller => :site, :action => :index, :anchor => "map=5/4/5"

    get :index, :lat => 4, :lon => 5, :zoom => 3
    assert_redirected_to :controller => :site, :action => :index, :anchor => "map=3/4/5"

    get :index, :layers => "T"
    assert_redirected_to :controller => :site, :action => :index, :anchor => "layers=T"

    get :index, :notes => "yes"
    assert_redirected_to :controller => :site, :action => :index, :anchor => "layers=N"

    get :index, :lat => 4, :lon => 5, :zoom => 3, :layers => "T"
    assert_redirected_to :controller => :site, :action => :index, :anchor => "map=3/4/5&layers=T"
  end

  # Test the permalink redirect
  def test_permalink
    get :permalink, :code => "wBz3--"
    assert_response :redirect
    assert_redirected_to :controller => :site, :action => :index, :anchor => "map=3/4.8779296875/3.955078125"

    get :permalink, :code => "wBz3--", :m => ""
    assert_response :redirect
    assert_redirected_to :controller => :site, :action => :index, :mlat => "4.8779296875", :mlon => "3.955078125", :anchor => "map=3/4.8779296875/3.955078125"

    get :permalink, :code => "wBz3--", :layers => "T"
    assert_response :redirect
    assert_redirected_to :controller => :site, :action => :index, :anchor => "map=3/4.8779296875/3.955078125&layers=T"

    get :permalink, :code => "wBz3--", :node => 1
    assert_response :redirect
    assert_redirected_to :controller => :browse, :action => :node, :id => 1, :anchor => "map=3/4.8779296875/3.955078125"

    get :permalink, :code => "wBz3--", :way => 2
    assert_response :redirect
    assert_redirected_to :controller => :browse, :action => :way, :id => 2, :anchor => "map=3/4.8779296875/3.955078125"

    get :permalink, :code => "wBz3--", :relation => 3
    assert_response :redirect
    assert_redirected_to :controller => :browse, :action => :relation, :id => 3, :anchor => "map=3/4.8779296875/3.955078125"

    get :permalink, :code => "wBz3--", :changeset => 4
    assert_response :redirect
    assert_redirected_to :controller => :browse, :action => :changeset, :id => 4, :anchor => "map=3/4.8779296875/3.955078125"
  end

  # Test the key page
  def test_key
    xhr :get, :key
    assert_response :success
    assert_template "key"
    assert_template :layout => false
  end

  # Test the edit page redirects when you aren't logged in
  def test_edit
    get :edit
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :referer => "/edit"
  end

  # Test the right editor gets used when the user hasn't set a preference
  def test_edit_without_preference
    get :edit, nil, :user => create(:user)
    assert_response :success
    assert_template "edit"
    assert_template :partial => "_#{DEFAULT_EDITOR}", :count => 1
  end

  # Test the right editor gets used when the user has set a preference
  def test_edit_with_preference
    user = create(:user)
    user.preferred_editor = "id"
    user.save!

    get :edit, nil, :user => user
    assert_response :success
    assert_template "edit"
    assert_template :partial => "_id", :count => 1

    user = create(:user)
    user.preferred_editor = "potlatch2"
    user.save!

    get :edit, nil, :user => user
    assert_response :success
    assert_template "edit"
    assert_template :partial => "_potlatch2", :count => 1

    user = create(:user)
    user.preferred_editor = "potlatch"
    user.save!

    get :edit, nil, :user => user
    assert_response :success
    assert_template "edit"
    assert_template :partial => "_potlatch", :count => 1

    user = create(:user)
    user.preferred_editor = "remote"
    user.save!

    get :edit, nil, :user => user
    assert_response :success
    assert_template "index"
  end

  # Test the right editor gets used when the URL has an override
  def test_edit_with_override
    get :edit, { :editor => "id" }, { :user => create(:user) }
    assert_response :success
    assert_template "edit"
    assert_template :partial => "_id", :count => 1

    get :edit, { :editor => "potlatch2" }, { :user => create(:user) }
    assert_response :success
    assert_template "edit"
    assert_template :partial => "_potlatch2", :count => 1

    get :edit, { :editor => "potlatch" }, { :user => create(:user) }
    assert_response :success
    assert_template "edit"
    assert_template :partial => "_potlatch", :count => 1

    get :edit, { :editor => "remote" }, { :user => create(:user) }
    assert_response :success
    assert_template "index"
  end

  # Test editing a specific node
  def test_edit_with_node
    user = create(:user)
    node = create(:node, :lat => 1.0, :lon => 1.0)

    get :edit, { :node => node.id }, { :user => user }
    assert_response :success
    assert_template "edit"
    assert_equal 1.0, assigns(:lat)
    assert_equal 1.0, assigns(:lon)
    assert_equal 18, assigns(:zoom)
  end

  # Test editing a specific way
  def test_edit_with_way
    user = create(:user)
    node = create(:node, :lat => 3, :lon => 3)
    way  = create(:way)
    create(:way_node, :node => node, :way => way)

    get :edit, { :way => way.id }, { :user => user }
    assert_response :success
    assert_template "edit"
    assert_equal 3.0, assigns(:lat)
    assert_equal 3.0, assigns(:lon)
    assert_equal 17, assigns(:zoom)
  end

  # Test editing a specific note
  def test_edit_with_note
    user = create(:user)
    note = create(:note) do |n|
      n.comments.create(:author_id => user.id)
    end

    get :edit, { :note => note.id }, { :user => user }
    assert_response :success
    assert_template "edit"
    assert_equal 1.0, assigns(:lat)
    assert_equal 1.0, assigns(:lon)
    assert_equal 17, assigns(:zoom)
  end

  # Test editing a specific GPX trace
  def test_edit_with_gpx
    user = create(:user)
    gpx  = create(:trace, :latitude => 1, :longitude => 1)

    get :edit, { :gpx => gpx.id }, { :user => user }
    assert_response :success
    assert_template "edit"
    assert_equal 1.0, assigns(:lat)
    assert_equal 1.0, assigns(:lon)
    assert_equal 16, assigns(:zoom)
  end

  # Test the edit page redirects
  def test_edit_redirect
    get :edit, :lat => 4, :lon => 5
    assert_redirected_to :controller => :site, :action => :edit, :anchor => "map=5/4/5"

    get :edit, :lat => 4, :lon => 5, :zoom => 3
    assert_redirected_to :controller => :site, :action => :edit, :anchor => "map=3/4/5"

    get :edit, :lat => 4, :lon => 5, :zoom => 3, :editor => "id"
    assert_redirected_to :controller => :site, :action => :edit, :editor => "id", :anchor => "map=3/4/5"
  end

  # Test the copyright page
  def test_copyright
    get :copyright
    assert_response :success
    assert_template "copyright"
  end

  # Test the welcome page
  def test_welcome
    get :welcome
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :referer => "/welcome"

    get :welcome, nil, :user => create(:user)
    assert_response :success
    assert_template "welcome"
  end

  # Test the fixthemap page
  def test_fixthemap
    get :fixthemap
    assert_response :success
    assert_template "fixthemap"
  end

  # Test the help page
  def test_help
    get :help
    assert_response :success
    assert_template "help"
  end

  # Test the about page
  def test_about
    get :about
    assert_response :success
    assert_template "about"
  end

  # Test the export page
  def test_export
    get :export
    assert_response :success
    assert_template "export"
    assert_template :layout => "map"

    xhr :get, :export
    assert_response :success
    assert_template "export"
    assert_template :layout => "xhr"
  end

  # Test the offline page
  def test_offline
    get :offline
    assert_response :success
    assert_template "offline"
  end

  # Test the rich text preview
  def test_preview
    xhr :post, :preview, :type => "html"
    assert_response :success

    xhr :post, :preview, :type => "markdown"
    assert_response :success

    xhr :post, :preview, :type => "text"
    assert_response :success
  end

  # Test the id frame
  def test_id
    get :id, nil, :user => create(:user)
    assert_response :success
    assert_template "id"
    assert_template :layout => false
  end
end

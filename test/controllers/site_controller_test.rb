require "test_helper"

class SiteControllerTest < ActionDispatch::IntegrationTest
  ##
  # setup oauth keys
  def setup
    super

    Settings.id_key = create(:client_application).key
    Settings.potlatch2_key = create(:client_application).key
  end

  ##
  # clear oauth keys
  def teardown
    Settings.id_key = nil
    Settings.potlatch2_key = nil
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
      { :path => "/help", :method => :get },
      { :controller => "site", :action => "help" }
    )
    assert_routing(
      { :path => "/about", :method => :get },
      { :controller => "site", :action => "about" }
    )
    assert_routing(
      { :path => "/about/locale", :method => :get },
      { :controller => "site", :action => "about", :about_locale => "locale" }
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
    get root_path

    assert_response :success
    assert_template "index"
  end

  # Test the index page redirects
  def test_index_redirect
    get root_path(:node => 123)
    assert_redirected_to :controller => :browse, :action => :node, :id => 123

    get root_path(:way => 123)
    assert_redirected_to :controller => :browse, :action => :way, :id => 123

    get root_path(:relation => 123)
    assert_redirected_to :controller => :browse, :action => :relation, :id => 123

    get root_path(:note => 123)
    assert_redirected_to :controller => :browse, :action => :note, :id => 123

    get root_path(:query => "test")
    assert_redirected_to :controller => :geocoder, :action => :search, :query => "test"

    get root_path(:lat => 4, :lon => 5)
    assert_redirected_to :controller => :site, :action => :index, :anchor => "map=5/4/5"

    get root_path(:lat => 4, :lon => 5, :zoom => 3)
    assert_redirected_to :controller => :site, :action => :index, :anchor => "map=3/4/5"

    get root_path(:layers => "T")
    assert_redirected_to :controller => :site, :action => :index, :anchor => "layers=T"

    get root_path(:notes => "yes")
    assert_redirected_to :controller => :site, :action => :index, :anchor => "layers=N"

    get root_path(:lat => 4, :lon => 5, :zoom => 3, :layers => "T")
    assert_redirected_to :controller => :site, :action => :index, :anchor => "map=3/4/5&layers=T"
  end

  # Test the permalink redirect
  def test_permalink
    get permalink_path(:code => "wBz3--")
    assert_response :redirect
    assert_redirected_to :controller => :site, :action => :index, :anchor => "map=3/4.8779296875/3.955078125"

    get permalink_path(:code => "wBz3--", :m => "")
    assert_response :redirect
    assert_redirected_to :controller => :site, :action => :index, :mlat => "4.8779296875", :mlon => "3.955078125", :anchor => "map=3/4.8779296875/3.955078125"

    get permalink_path(:code => "wBz3--", :layers => "T")
    assert_response :redirect
    assert_redirected_to :controller => :site, :action => :index, :anchor => "map=3/4.8779296875/3.955078125&layers=T"

    get permalink_path(:code => "wBz3--", :node => 1)
    assert_response :redirect
    assert_redirected_to :controller => :browse, :action => :node, :id => 1, :anchor => "map=3/4.8779296875/3.955078125"

    get permalink_path(:code => "wBz3--", :way => 2)
    assert_response :redirect
    assert_redirected_to :controller => :browse, :action => :way, :id => 2, :anchor => "map=3/4.8779296875/3.955078125"

    get permalink_path(:code => "wBz3--", :relation => 3)
    assert_response :redirect
    assert_redirected_to :controller => :browse, :action => :relation, :id => 3, :anchor => "map=3/4.8779296875/3.955078125"

    get permalink_path(:code => "wBz3--", :changeset => 4)
    assert_response :redirect
    assert_redirected_to :controller => :browse, :action => :changeset, :id => 4, :anchor => "map=3/4.8779296875/3.955078125"
  end

  # Test the key page
  def test_key
    get key_path, :xhr => true

    assert_response :success
    assert_template "key"
    assert_template :layout => false
  end

  # Test the edit page redirects when you aren't logged in
  def test_edit
    get edit_path

    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :login, :referer => "/edit"
  end

  # Test the error when trying to edit without public edits
  def test_edit_non_public
    session_for(create(:user, :data_public => false))

    get edit_path

    assert_response :success
    assert_template "edit"
    assert_select "a[href='https://wiki.openstreetmap.org/wiki/Disabling_anonymous_edits']"
  end

  # Test the right editor gets used when the user hasn't set a preference
  def test_edit_without_preference
    session_for(create(:user))

    get edit_path

    assert_response :success
    assert_template "edit"
    assert_template :partial => "_#{Settings.default_editor}", :count => 1
  end

  # Test the right editor gets used when the user has set a preference
  def test_edit_with_preference
    user = create(:user)
    user.preferred_editor = "id"
    user.save!
    session_for(user)

    get edit_path
    assert_response :success
    assert_template "edit"
    assert_template :partial => "_id", :count => 1

    user.preferred_editor = "potlatch2"
    user.save!

    get edit_path
    assert_response :success
    assert_template "edit"
    assert_template :partial => "_potlatch2", :count => 1

    user.preferred_editor = "potlatch"
    user.save!

    get edit_path
    assert_response :success
    assert_template "edit"
    assert_template :partial => "_potlatch", :count => 1

    user.preferred_editor = "remote"
    user.save!

    get edit_path
    assert_response :success
    assert_template "index"
  end

  # Test the right editor gets used when the URL has an override
  def test_edit_with_override
    session_for(create(:user))

    get edit_path(:editor => "id")
    assert_response :success
    assert_template "edit"
    assert_template :partial => "_id", :count => 1

    get edit_path(:editor => "potlatch2")
    assert_response :success
    assert_template "edit"
    assert_template :partial => "_potlatch2", :count => 1

    get edit_path(:editor => "potlatch")
    assert_response :success
    assert_template "edit"
    assert_template :partial => "_potlatch", :count => 1

    get edit_path(:editor => "remote")
    assert_response :success
    assert_template "index"
  end

  # Test editing a specific node
  def test_edit_with_node
    user = create(:user)
    node = create(:node, :lat => 1.0, :lon => 1.0)
    session_for(user)

    get edit_path(:node => node.id)

    assert_response :success
    assert_template "edit"
    assert_equal 1.0, assigns(:lat)
    assert_equal 1.0, assigns(:lon)
    assert_equal 18, assigns(:zoom)
  end

  # Test editing inaccessible nodes
  def test_edit_with_inaccessible_nodes
    user = create(:user)
    deleted_node = create(:node, :lat => 1.0, :lon => 1.0, :visible => false)
    session_for(user)

    get edit_path(:node => 99999)
    assert_response :success
    assert_template "edit"
    assert_nil assigns(:lat)
    assert_nil assigns(:lon)
    assert_nil assigns(:zoom)

    get edit_path(:node => deleted_node.id)
    assert_response :success
    assert_template "edit"
    assert_nil assigns(:lat)
    assert_nil assigns(:lon)
    assert_nil assigns(:zoom)
  end

  # Test editing a specific way
  def test_edit_with_way
    user = create(:user)
    node = create(:node, :lat => 3, :lon => 3)
    way = create(:way)
    create(:way_node, :node => node, :way => way)
    session_for(user)

    get edit_path(:way => way.id)
    assert_response :success
    assert_template "edit"
    assert_equal 3.0, assigns(:lat)
    assert_equal 3.0, assigns(:lon)
    assert_equal 17, assigns(:zoom)
  end

  # Test editing inaccessible ways
  def test_edit_with_inaccessible_ways
    user = create(:user)
    deleted_way = create(:way, :visible => false)
    session_for(user)

    get edit_path(:way => 99999)
    assert_response :success
    assert_template "edit"
    assert_nil assigns(:lat)
    assert_nil assigns(:lon)
    assert_nil assigns(:zoom)

    get edit_path(:way => deleted_way.id)
    assert_response :success
    assert_template "edit"
    assert_nil assigns(:lat)
    assert_nil assigns(:lon)
    assert_nil assigns(:zoom)
  end

  # Test editing a specific note
  def test_edit_with_note
    user = create(:user)
    note = create(:note) do |n|
      n.comments.create(:author_id => user.id)
    end
    session_for(user)

    get edit_path(:note => note.id)
    assert_response :success
    assert_template "edit"
    assert_equal 1.0, assigns(:lat)
    assert_equal 1.0, assigns(:lon)
    assert_equal 17, assigns(:zoom)
  end

  # Test editing inaccessible notes
  def test_edit_with_inaccessible_notes
    user = create(:user)
    deleted_note = create(:note, :status => "hidden") do |n|
      n.comments.create(:author_id => user.id)
    end
    session_for(user)

    get edit_path(:note => 99999)
    assert_response :success
    assert_template "edit"
    assert_nil assigns(:lat)
    assert_nil assigns(:lon)
    assert_nil assigns(:zoom)

    get edit_path(:note => deleted_note.id)
    assert_response :success
    assert_template "edit"
    assert_nil assigns(:lat)
    assert_nil assigns(:lon)
    assert_nil assigns(:zoom)
  end

  # Test editing a specific GPX trace
  def test_edit_with_gpx
    user = create(:user)
    gpx = create(:trace, :latitude => 1, :longitude => 1)
    session_for(user)

    get edit_path(:gpx => gpx.id)
    assert_response :success
    assert_template "edit"
    assert_equal 1.0, assigns(:lat)
    assert_equal 1.0, assigns(:lon)
    assert_equal 16, assigns(:zoom)
  end

  # Test editing inaccessible GPX traces
  def test_edit_with_inaccessible_gpxes
    user = create(:user)
    deleted_gpx = create(:trace, :deleted, :latitude => 1, :longitude => 1)
    private_gpx = create(:trace, :latitude => 1, :longitude => 1, :visibility => "private")
    session_for(user)

    get edit_path(:gpx => 99999)
    assert_response :success
    assert_template "edit"
    assert_nil assigns(:lat)
    assert_nil assigns(:lon)
    assert_nil assigns(:zoom)

    get edit_path(:gpx => deleted_gpx.id)
    assert_response :success
    assert_template "edit"
    assert_nil assigns(:lat)
    assert_nil assigns(:lon)
    assert_nil assigns(:zoom)

    get edit_path(:gpx => private_gpx.id)
    assert_response :success
    assert_template "edit"
    assert_nil assigns(:lat)
    assert_nil assigns(:lon)
    assert_nil assigns(:zoom)
  end

  # Test the edit page redirects
  def test_edit_redirect
    get edit_path(:lat => 4, :lon => 5)
    assert_redirected_to :controller => :site, :action => :edit, :anchor => "map=5/4/5"

    get edit_path(:lat => 4, :lon => 5, :zoom => 3)
    assert_redirected_to :controller => :site, :action => :edit, :anchor => "map=3/4/5"

    get edit_path(:lat => 4, :lon => 5, :zoom => 3, :editor => "id")
    assert_redirected_to :controller => :site, :action => :edit, :editor => "id", :anchor => "map=3/4/5"
  end

  # Test the copyright page
  def test_copyright
    get copyright_path
    assert_response :success
    assert_template "copyright"
    assert_select "div[lang='en'][dir='ltr']"

    get copyright_path(:copyright_locale => "fr")
    assert_response :success
    assert_template "copyright"
    assert_select "div[lang='fr'][dir='ltr']"

    get copyright_path(:copyright_locale => "ar")
    assert_response :success
    assert_template "copyright"
    assert_select "div[lang='ar'][dir='rtl']"
  end

  # Test the welcome page
  def test_welcome
    get welcome_path
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :login, :referer => "/welcome"

    session_for(create(:user))
    get welcome_path
    assert_response :success
    assert_template "welcome"
  end

  # Test the fixthemap page
  def test_fixthemap
    get fixthemap_path
    assert_response :success
    assert_template "fixthemap"
  end

  # Test the help page
  def test_help
    get help_path
    assert_response :success
    assert_template "help"
  end

  # Test the about page
  def test_about
    get about_path
    assert_response :success
    assert_template "about"
    assert_select "div[lang='en'][dir='ltr']"

    get about_path(:about_locale => "fr")
    assert_response :success
    assert_template "about"
    assert_select "div[lang='fr'][dir='ltr']"

    get about_path(:about_locale => "ar")
    assert_response :success
    assert_template "about"
    assert_select "div[lang='ar'][dir='rtl']"
  end

  # Test the export page
  def test_export
    get export_path
    assert_response :success
    assert_template "export"
    assert_template :layout => "map"

    get export_path, :xhr => true
    assert_response :success
    assert_template "export"
    assert_template :layout => "xhr"
  end

  # Test the offline page
  def test_offline
    get offline_path
    assert_response :success
    assert_template "offline"
  end

  # Test the rich text preview
  def test_preview
    post preview_path(:type => "html"), :xhr => true
    assert_response :success

    post preview_path(:type => "markdown"), :xhr => true
    assert_response :success

    post preview_path(:type => "text"), :xhr => true
    assert_response :success
  end

  # Test the id frame
  def test_id
    session_for(create(:user))

    get id_path

    assert_response :success
    assert_template "id"
    assert_template :layout => false
  end
end

require "test_helper"

class Oauth2ApplicationsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/oauth2/applications", :method => :get },
      { :controller => "oauth2_applications", :action => "index" }
    )
    assert_routing(
      { :path => "/oauth2/applications", :method => :post },
      { :controller => "oauth2_applications", :action => "create" }
    )
    assert_routing(
      { :path => "/oauth2/applications/new", :method => :get },
      { :controller => "oauth2_applications", :action => "new" }
    )
    assert_routing(
      { :path => "/oauth2/applications/1/edit", :method => :get },
      { :controller => "oauth2_applications", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/oauth2/applications/1", :method => :get },
      { :controller => "oauth2_applications", :action => "show", :id => "1" }
    )
    assert_routing(
      { :path => "/oauth2/applications/1", :method => :patch },
      { :controller => "oauth2_applications", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/oauth2/applications/1", :method => :put },
      { :controller => "oauth2_applications", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/oauth2/applications/1", :method => :delete },
      { :controller => "oauth2_applications", :action => "destroy", :id => "1" }
    )
  end

  def test_index
    user = create(:user)
    create_list(:oauth_application, 2, :owner => user)

    get oauth_applications_path
    assert_response :redirect
    assert_redirected_to login_path(:referer => oauth_applications_path)

    session_for(user)

    get oauth_applications_path
    assert_response :success
    assert_template "oauth2_applications/index"
    assert_select "tbody tr", 2
  end

  def test_new
    user = create(:user)

    get new_oauth_application_path
    assert_response :redirect
    assert_redirected_to login_path(:referer => new_oauth_application_path)

    session_for(user)

    get new_oauth_application_path
    assert_response :success
    assert_template "oauth2_applications/new"
    assert_select "form", 1 do
      assert_select "input#oauth2_application_name", 1
      assert_select "textarea#oauth2_application_redirect_uri", 1
      assert_select "input#oauth2_application_confidential", 1
      Oauth.scopes.each do |scope|
        assert_select "input#oauth2_application_scopes_#{scope.name}", 1
      end
    end
  end

  def test_create
    user = create(:user)

    assert_difference "Doorkeeper::Application.count", 0 do
      post oauth_applications_path
    end
    assert_response :forbidden

    session_for(user)

    assert_difference "Doorkeeper::Application.count", 0 do
      post oauth_applications_path(:oauth2_application => {
                                     :name => "Test Application"
                                   })
    end
    assert_response :success
    assert_template "oauth2_applications/new"

    assert_difference "Doorkeeper::Application.count", 0 do
      post oauth_applications_path(:oauth2_application => {
                                     :name => "Test Application",
                                     :redirect_uri => "https://test.example.com/",
                                     :scopes => ["bad_scope"]
                                   })
    end
    assert_response :success
    assert_template "oauth2_applications/new"

    assert_difference "Doorkeeper::Application.count", 1 do
      post oauth_applications_path(:oauth2_application => {
                                     :name => "Test Application",
                                     :redirect_uri => "https://test.example.com/",
                                     :scopes => ["read_prefs"]
                                   })
    end
    assert_response :redirect
    assert_redirected_to oauth_application_path(:id => Doorkeeper::Application.find_by(:name => "Test Application").id)
  end

  def test_create_privileged
    session_for(create(:user))

    assert_difference "Doorkeeper::Application.count", 0 do
      post oauth_applications_path(:oauth2_application => {
                                     :name => "Test Application",
                                     :redirect_uri => "https://test.example.com/",
                                     :scopes => ["read_email"]
                                   })
    end
    assert_response :success
    assert_template "oauth2_applications/new"

    session_for(create(:administrator_user))

    assert_difference "Doorkeeper::Application.count", 1 do
      post oauth_applications_path(:oauth2_application => {
                                     :name => "Test Application",
                                     :redirect_uri => "https://test.example.com/",
                                     :scopes => ["read_email"]
                                   })
    end
    assert_response :redirect
    assert_redirected_to oauth_application_path(:id => Doorkeeper::Application.find_by(:name => "Test Application").id)
  end

  def test_show
    user = create(:user)
    client = create(:oauth_application, :owner => user)
    other_client = create(:oauth_application)

    get oauth_application_path(:id => client)
    assert_response :redirect
    assert_redirected_to login_path(:referer => oauth_application_path(:id => client.id))

    session_for(user)

    get oauth_application_path(:id => other_client)
    assert_response :not_found
    assert_template "oauth2_applications/not_found"

    get oauth_application_path(:id => client)
    assert_response :success
    assert_template "oauth2_applications/show"
  end

  def test_edit
    user = create(:user)
    client = create(:oauth_application, :owner => user)
    other_client = create(:oauth_application)

    get edit_oauth_application_path(:id => client)
    assert_response :redirect
    assert_redirected_to login_path(:referer => edit_oauth_application_path(:id => client.id))

    session_for(user)

    get edit_oauth_application_path(:id => other_client)
    assert_response :not_found
    assert_template "oauth2_applications/not_found"

    get edit_oauth_application_path(:id => client)
    assert_response :success
    assert_template "oauth2_applications/edit"
    assert_select "form", 1 do
      assert_select "input#oauth2_application_name", 1
      assert_select "textarea#oauth2_application_redirect_uri", 1
      assert_select "input#oauth2_application_confidential", 1
      Oauth.scopes.each do |scope|
        assert_select "input#oauth2_application_scopes_#{scope.name}", 1
      end
    end
  end

  def test_update
    user = create(:user)
    client = create(:oauth_application, :owner => user)
    other_client = create(:oauth_application)

    put oauth_application_path(:id => client)
    assert_response :forbidden

    session_for(user)

    put oauth_application_path(:id => other_client)
    assert_response :not_found
    assert_template "oauth2_applications/not_found"

    put oauth_application_path(:id => client,
                               :oauth2_application => {
                                 :name => "New Name",
                                 :redirect_uri => nil
                               })
    assert_response :success
    assert_template "oauth2_applications/edit"

    put oauth_application_path(:id => client,
                               :oauth2_application => {
                                 :name => "New Name",
                                 :redirect_uri => "https://new.example.com/url"
                               })
    assert_response :redirect
    assert_redirected_to oauth_application_path(:id => client.id)
  end

  def test_destroy
    user = create(:user)
    client = create(:oauth_application, :owner => user)
    other_client = create(:oauth_application)

    assert_difference "Doorkeeper::Application.count", 0 do
      delete oauth_application_path(:id => client)
    end
    assert_response :forbidden

    session_for(user)

    assert_difference "Doorkeeper::Application.count", 0 do
      delete oauth_application_path(:id => other_client)
    end
    assert_response :not_found
    assert_template "oauth2_applications/not_found"

    assert_difference "Doorkeeper::Application.count", -1 do
      delete oauth_application_path(:id => client)
    end
    assert_response :redirect
    assert_redirected_to oauth_applications_path
  end
end

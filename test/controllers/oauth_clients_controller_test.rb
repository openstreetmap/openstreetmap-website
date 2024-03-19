require "test_helper"

class OauthClientsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/username/oauth_clients", :method => :get },
      { :controller => "oauth_clients", :action => "index", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/oauth_clients/new", :method => :get },
      { :controller => "oauth_clients", :action => "new", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/oauth_clients", :method => :post },
      { :controller => "oauth_clients", :action => "create", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/oauth_clients/1", :method => :get },
      { :controller => "oauth_clients", :action => "show", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/oauth_clients/1/edit", :method => :get },
      { :controller => "oauth_clients", :action => "edit", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/oauth_clients/1", :method => :put },
      { :controller => "oauth_clients", :action => "update", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/oauth_clients/1", :method => :delete },
      { :controller => "oauth_clients", :action => "destroy", :display_name => "username", :id => "1" }
    )
  end

  def test_index
    user = create(:user)
    create_list(:client_application, 2, :user => user)
    create_list(:access_token, 2, :user => user)

    get oauth_clients_path(user)
    assert_redirected_to login_path(:referer => oauth_clients_path(user))

    session_for(user)

    get oauth_clients_path(user)
    assert_response :success
    assert_template "index"
    assert_select "li.client_application", 2
  end

  def test_new
    user = create(:user)

    get new_oauth_client_path(user)
    assert_redirected_to login_path(:referer => new_oauth_client_path(user))

    session_for(user)

    get new_oauth_client_path(user)
    assert_response :success
    assert_template "new"
    assert_select "form", 1 do
      assert_select "input#client_application_name", 1
      assert_select "input#client_application_url", 1
      assert_select "input#client_application_callback_url", 1
      assert_select "input#client_application_support_url", 1
      ClientApplication.all_permissions.each do |perm|
        assert_select "input#client_application_#{perm}", 1
      end
    end
  end

  def test_new_disabled
    user = create(:user)

    with_settings(:oauth_10_registration => false) do
      get new_oauth_client_path(user)
      assert_redirected_to login_path(:referer => new_oauth_client_path(user))

      session_for(user)

      get new_oauth_client_path(user)
      assert_redirected_to oauth_clients_path(user)
    end
  end

  def test_create
    user = create(:user)

    assert_difference "ClientApplication.count", 0 do
      post oauth_clients_path(user)
    end
    assert_response :forbidden

    session_for(user)

    assert_difference "ClientApplication.count", 0 do
      post oauth_clients_path(user, :client_application => { :name => "Test Application" })
    end
    assert_response :success
    assert_template "new"

    assert_difference "ClientApplication.count", 1 do
      post oauth_clients_path(user, :client_application => { :name => "Test Application",
                                                             :url => "http://test.example.com/" })
    end
    assert_redirected_to oauth_client_path(:id => ClientApplication.find_by(:name => "Test Application").id)
  end

  def test_show
    user = create(:user)
    client = create(:client_application, :user => user)
    other_client = create(:client_application)

    get oauth_client_path(user, client)
    assert_redirected_to login_path(:referer => oauth_client_path(user, client.id))

    session_for(user)

    get oauth_client_path(user, other_client)
    assert_response :not_found
    assert_template "not_found"

    get oauth_client_path(user, client)
    assert_response :success
    assert_template "show"
  end

  def test_edit
    user = create(:user)
    client = create(:client_application, :user => user)
    other_client = create(:client_application)

    get edit_oauth_client_path(user, client)
    assert_redirected_to login_path(:referer => edit_oauth_client_path(user, client.id))

    session_for(user)

    get edit_oauth_client_path(user, other_client)
    assert_response :not_found
    assert_template "not_found"

    get edit_oauth_client_path(user, client)
    assert_response :success
    assert_template "edit"
    assert_select "form", 1 do
      assert_select "input#client_application_name", 1
      assert_select "input#client_application_url", 1
      assert_select "input#client_application_callback_url", 1
      assert_select "input#client_application_support_url", 1
      ClientApplication.all_permissions.each do |perm|
        assert_select "input#client_application_#{perm}", 1
      end
    end
  end

  def test_update
    user = create(:user)
    client = create(:client_application, :user => user)
    other_client = create(:client_application)

    put oauth_client_path(user, client)
    assert_response :forbidden

    session_for(user)

    put oauth_client_path(user, other_client)
    assert_response :not_found
    assert_template "not_found"

    put oauth_client_path(user, client, :client_application => { :name => "New Name", :url => nil })
    assert_response :success
    assert_template "edit"

    put oauth_client_path(user, client, :client_application => { :name => "New Name", :url => "http://new.example.com/url" })
    assert_redirected_to oauth_client_path(:id => client.id)
  end

  def test_destroy
    user = create(:user)
    client = create(:client_application, :user => user)
    other_client = create(:client_application)

    assert_difference "ClientApplication.count", 0 do
      delete oauth_client_path(user, client)
    end
    assert_response :forbidden

    session_for(user)

    assert_difference "ClientApplication.count", 0 do
      delete oauth_client_path(user, other_client)
    end
    assert_response :not_found
    assert_template "not_found"

    assert_difference "ClientApplication.count", -1 do
      delete oauth_client_path(user, client)
    end
    assert_redirected_to oauth_clients_path(user)
  end
end

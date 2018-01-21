require "test_helper"

class OauthClientsControllerTest < ActionController::TestCase
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

    get :index,
        :params => { :display_name => user.display_name }
    assert_response :redirect
    assert_redirected_to login_path(:referer => oauth_clients_path(:display_name => user.display_name))

    get :index,
        :params => { :display_name => user.display_name },
        :session => { :user => user }
    assert_response :success
    assert_template "index"
    assert_select "div.client_application", 2
  end

  def test_new
    user = create(:user)

    get :new,
        :params => { :display_name => user.display_name }
    assert_response :redirect
    assert_redirected_to login_path(:referer => new_oauth_client_path(:display_name => user.display_name))

    get :new,
        :params => { :display_name => user.display_name },
        :session => { :user => user }
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

  def test_create
    user = create(:user)

    assert_difference "ClientApplication.count", 0 do
      post :create, :params => { :display_name => user.display_name }
    end
    assert_response :forbidden

    assert_difference "ClientApplication.count", 0 do
      post :create,
           :params => { :display_name => user.display_name,
                        :client_application => { :name => "Test Application" } },
           :session => { :user => user }
    end
    assert_response :success
    assert_template "new"

    assert_difference "ClientApplication.count", 1 do
      post :create,
           :params => { :display_name => user.display_name,
                        :client_application => { :name => "Test Application",
                                                 :url => "http://test.example.com/" } },
           :session => { :user => user }
    end
    assert_response :redirect
    assert_redirected_to oauth_client_path(:id => ClientApplication.find_by(:name => "Test Application").id)
  end

  def test_show
    user = create(:user)
    client = create(:client_application, :user => user)
    other_client = create(:client_application)

    get :show,
        :params => { :display_name => user.display_name, :id => client.id }
    assert_response :redirect
    assert_redirected_to login_path(:referer => oauth_client_path(:display_name => user.display_name, :id => client.id))

    get :show,
        :params => { :display_name => user.display_name, :id => other_client.id },
        :session => { :user => user }
    assert_response :not_found
    assert_template "not_found"

    get :show,
        :params => { :display_name => user.display_name, :id => client.id },
        :session => { :user => user }
    assert_response :success
    assert_template "show"
  end

  def test_edit
    user = create(:user)
    client = create(:client_application, :user => user)
    other_client = create(:client_application)

    get :edit,
        :params => { :display_name => user.display_name, :id => client.id }
    assert_response :redirect
    assert_redirected_to login_path(:referer => edit_oauth_client_path(:display_name => user.display_name, :id => client.id))

    get :edit,
        :params => { :display_name => user.display_name, :id => other_client.id },
        :session => { :user => user }
    assert_response :not_found
    assert_template "not_found"

    get :edit,
        :params => { :display_name => user.display_name, :id => client.id },
        :session => { :user => user }
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

    put :update,
        :params => { :display_name => user.display_name, :id => client.id }
    assert_response :forbidden

    put :update,
        :params => { :display_name => user.display_name, :id => other_client.id },
        :session => { :user => user }
    assert_response :not_found
    assert_template "not_found"

    put :update,
        :params => { :display_name => user.display_name,
                     :id => client.id,
                     :client_application => { :name => "New Name", :url => nil } },
        :session => { :user => user }
    assert_response :success
    assert_template "edit"

    put :update,
        :params => { :display_name => user.display_name,
                     :id => client.id,
                     :client_application => { :name => "New Name", :url => "http://new.example.com/url" } },
        :session => { :user => user }
    assert_response :redirect
    assert_redirected_to oauth_client_path(:id => client.id)
  end

  def test_destroy
    user = create(:user)
    client = create(:client_application, :user => user)
    other_client = create(:client_application)

    assert_difference "ClientApplication.count", 0 do
      delete :destroy,
             :params => { :display_name => user.display_name, :id => client.id }
    end
    assert_response :forbidden

    assert_difference "ClientApplication.count", 0 do
      delete :destroy,
             :params => { :display_name => user.display_name, :id => other_client.id },
             :session => { :user => user }
    end
    assert_response :not_found
    assert_template "not_found"

    assert_difference "ClientApplication.count", -1 do
      delete :destroy,
             :params => { :display_name => user.display_name, :id => client.id },
             :session => { :user => user }
    end
    assert_response :redirect
    assert_redirected_to oauth_clients_path(:display_name => user.display_name)
  end
end

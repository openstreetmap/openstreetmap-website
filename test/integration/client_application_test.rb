require File.dirname(__FILE__) + '/../test_helper'

class ClientApplicationTest < ActionController::IntegrationTest
  fixtures :users, :client_applications

  ##
  # run through the procedure of creating a client application and checking
  # that it shows up on the user's account page.
  def test_create_application
    get '/login'
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    post '/login', {'username' => "test@example.com", 'password' => "test", :referer => '/user/test2'}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'user/view'
    get '/user/test2/account'
    assert_response :success
    assert_template 'user/account'

    # check that the form to allow new client application creations exists
    assert_in_heading do
      assert_select "ul.secondary-actions li a[href='/user/test2/oauth_clients']"
    end

    # now we follow the link to the oauth client list
    get '/user/test2/oauth_clients'
    assert_response :success
    assert_in_body do
      assert_select "a[href='/user/test2/oauth_clients/new']"
    end

    # now we follow the link to the new oauth client page
    get '/user/test2/oauth_clients/new'
    assert_response :success
    assert_in_heading do
      assert_select "h1", "Register a new application"
    end
    assert_in_body do
      assert_select "form[action='/user/test2/oauth_clients']" do
        [ :name, :url, :callback_url, :support_url ].each do |inp|
          assert_select "input[name=?]", "client_application[#{inp}]"
        end
        ClientApplication.all_permissions.each do |perm|
          assert_select "input[name=?]", "client_application[#{perm}]"
        end
      end
    end

    post '/user/test2/oauth_clients', {
      'client_application[name]' => 'My New App',
      'client_application[url]' => 'http://my.new.app.org/',
      'client_application[callback_url]' => 'http://my.new.app.org/callback',
      'client_application[support_url]' => 'http://my.new.app.org/support'}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'oauth_clients/show'
    assert_equal 'Registered the information successfully', flash[:notice]

    # now go back to the account page and check its listed under this user
    get '/user/test2/oauth_clients'
    assert_response :success
    assert_template 'oauth_clients/index'
    assert_in_body { assert_select "div>a", "My New App" }
  end

  ##
  # fake client workflow.
  # this acts like a 3rd party client trying to access the site.
  def test_3rd_party_token
    # apparently the oauth gem doesn't really support being used inside integration
    # tests, as its too tied into the HTTP headers and stuff that it signs.
  end

  ##
  # utility method to make the HTML screening easier to read.
  def assert_in_heading
    assert_select "html:root" do
      assert_select "body" do
        assert_select "div.wrapper" do
          assert_select "div.content-heading" do
            yield
          end
        end
      end
    end
  end

  ##
  # utility method to make the HTML screening easier to read.
  def assert_in_body
    assert_select "html:root" do
      assert_select "body" do
        assert_select "div#content" do
          yield
        end
      end
    end
  end

end

require "test_helper"

class Oauth2AuthorizationsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/oauth2/authorize", :method => :get },
      { :controller => "oauth2_authorizations", :action => "new" }
    )
    assert_routing(
      { :path => "/oauth2/authorize", :method => :post },
      { :controller => "oauth2_authorizations", :action => "create" }
    )
    assert_routing(
      { :path => "/oauth2/authorize", :method => :delete },
      { :controller => "oauth2_authorizations", :action => "destroy" }
    )
    assert_routing(
      { :path => "/oauth2/authorize/native", :method => :get },
      { :controller => "oauth2_authorizations", :action => "show" }
    )
  end

  def test_new
    application = create(:oauth_application, :scopes => "write_api")

    get oauth_authorization_path(:client_id => application.uid,
                                 :redirect_uri => application.redirect_uri,
                                 :response_type => "code",
                                 :scope => "write_api")
    assert_response :redirect
    assert_redirected_to login_path(:referer => oauth_authorization_path(:client_id => application.uid,
                                                                         :redirect_uri => application.redirect_uri,
                                                                         :response_type => "code",
                                                                         :scope => "write_api"))

    session_for(create(:user))

    get oauth_authorization_path(:client_id => application.uid,
                                 :redirect_uri => application.redirect_uri,
                                 :response_type => "code",
                                 :scope => "write_api")
    assert_response :success
    assert_template "oauth2_authorizations/new"
  end

  def test_new_native
    application = create(:oauth_application, :scopes => "write_api", :redirect_uri => "urn:ietf:wg:oauth:2.0:oob")

    get oauth_authorization_path(:client_id => application.uid,
                                 :redirect_uri => application.redirect_uri,
                                 :response_type => "code",
                                 :scope => "write_api")
    assert_response :redirect
    assert_redirected_to login_path(:referer => oauth_authorization_path(:client_id => application.uid,
                                                                         :redirect_uri => application.redirect_uri,
                                                                         :response_type => "code",
                                                                         :scope => "write_api"))

    session_for(create(:user))

    get oauth_authorization_path(:client_id => application.uid,
                                 :redirect_uri => application.redirect_uri,
                                 :response_type => "code",
                                 :scope => "write_api")
    assert_response :success
    assert_template "oauth2_authorizations/new"
  end

  def test_new_bad_uri
    application = create(:oauth_application, :scopes => "write_api")

    session_for(create(:user))

    get oauth_authorization_path(:client_id => application.uid,
                                 :redirect_uri => "https://bad.example.com/",
                                 :response_type => "code",
                                 :scope => "write_api")
    assert_response :success
    assert_template "oauth2_authorizations/error"
    assert_select "p", "The requested redirect uri is malformed or doesn't match client redirect URI."
  end

  def test_new_bad_scope
    application = create(:oauth_application, :scopes => "write_api")

    session_for(create(:user))

    get oauth_authorization_path(:client_id => application.uid,
                                 :redirect_uri => application.redirect_uri,
                                 :response_type => "code",
                                 :scope => "bad_scope")
    assert_response :success
    assert_template "oauth2_authorizations/error"
    assert_select "p", "The requested scope is invalid, unknown, or malformed."

    get oauth_authorization_path(:client_id => application.uid,
                                 :redirect_uri => application.redirect_uri,
                                 :response_type => "code",
                                 :scope => "write_prefs")
    assert_response :success
    assert_template "oauth2_authorizations/error"
    assert_select "p", "The requested scope is invalid, unknown, or malformed."
  end

  def test_create
    application = create(:oauth_application, :scopes => "write_api")

    post oauth_authorization_path(:client_id => application.uid,
                                  :redirect_uri => application.redirect_uri,
                                  :response_type => "code",
                                  :scope => "write_api")
    assert_response :forbidden

    session_for(create(:user))

    post oauth_authorization_path(:client_id => application.uid,
                                  :redirect_uri => application.redirect_uri,
                                  :response_type => "code",
                                  :scope => "write_api")
    assert_response :redirect
    assert_redirected_to(/^#{Regexp.escape(application.redirect_uri)}\?code=/)
  end

  def test_create_native
    application = create(:oauth_application, :scopes => "write_api", :redirect_uri => "urn:ietf:wg:oauth:2.0:oob")

    post oauth_authorization_path(:client_id => application.uid,
                                  :redirect_uri => application.redirect_uri,
                                  :response_type => "code",
                                  :scope => "write_api")
    assert_response :forbidden

    session_for(create(:user))

    post oauth_authorization_path(:client_id => application.uid,
                                  :redirect_uri => application.redirect_uri,
                                  :response_type => "code",
                                  :scope => "write_api")
    assert_response :redirect
    assert_equal native_oauth_authorization_path, URI.parse(response.location).path
    follow_redirect!
    assert_response :success
    assert_template "oauth2_authorizations/show"
  end

  def test_destroy
    application = create(:oauth_application)

    delete oauth_authorization_path(:client_id => application.uid,
                                    :redirect_uri => application.redirect_uri,
                                    :response_type => "code",
                                    :scope => "write_api")
    assert_response :forbidden

    session_for(create(:user))

    delete oauth_authorization_path(:client_id => application.uid,
                                    :redirect_uri => application.redirect_uri,
                                    :response_type => "code",
                                    :scope => "write_api")
    assert_response :redirect
    assert_redirected_to(/^#{Regexp.escape(application.redirect_uri)}\?error=access_denied/)
  end

  def test_destroy_native
    application = create(:oauth_application, :redirect_uri => "urn:ietf:wg:oauth:2.0:oob")

    delete oauth_authorization_path(:client_id => application.uid,
                                    :redirect_uri => application.redirect_uri,
                                    :response_type => "code",
                                    :scope => "write_api")
    assert_response :forbidden

    session_for(create(:user))

    delete oauth_authorization_path(:client_id => application.uid,
                                    :redirect_uri => application.redirect_uri,
                                    :response_type => "code",
                                    :scope => "write_api")
    assert_response :bad_request
  end
end

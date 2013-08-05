require File.dirname(__FILE__) + '/../test_helper'

class OAuthTest < ActionDispatch::IntegrationTest
  fixtures :users, :client_applications, :gpx_files

  include OAuth::Helper

  def test_oauth10_web_app
    client = client_applications(:oauth_web_app)

    post_via_redirect "/login", 
      :username => client.user.email, :password => "test"
    assert_response :success

    signed_get "/oauth/request_token", :consumer => client
    assert_response :success
    token = parse_token(response)
    assert_instance_of RequestToken, token
    assert_not_nil token.created_at
    assert_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, client.permissions

    post "/oauth/authorize", 
      :oauth_token => token.token, 
      :allow_read_prefs => true, :allow_write_prefs => true
    assert_response :redirect
    assert_redirected_to "http://some.web.app.org/callback?oauth_token=#{token.token}"
    token.reload
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, [ :allow_read_prefs ]

    signed_get "/oauth/access_token", :consumer => client, :token => token
    assert_response :success
    token.reload
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_not_nil token.invalidated_at
    token = parse_token(response)
    assert_instance_of AccessToken, token
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, [ :allow_read_prefs ]

    signed_get "/api/0.6/user/preferences", :consumer => client, :token => token
    assert_response :success

    post "/oauth/revoke", :token => token.token
    assert_redirected_to oauth_clients_url(token.user.display_name)
    token = OauthToken.find_by_token(token.token)
    assert_not_nil token.invalidated_at

    signed_get "/api/0.6/user/preferences", :consumer => client, :token => token
    assert_response :unauthorized

    signed_get "/oauth/request_token", :consumer => client
    assert_response :success
    token = parse_token(response)
    assert_instance_of RequestToken, token
    assert_not_nil token.created_at
    assert_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, client.permissions

    post "/oauth/authorize", 
      :oauth_token => token.token, 
      :oauth_callback => "http://another.web.app.org/callback", 
      :allow_write_api => true, :allow_read_gpx => true
    assert_response :redirect
    assert_redirected_to "http://another.web.app.org/callback?oauth_token=#{token.token}"
    token.reload
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, [ :allow_write_api, :allow_read_gpx ]

    signed_get "/oauth/access_token", :consumer => client, :token => token
    assert_response :success
    token.reload
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_not_nil token.invalidated_at
    token = parse_token(response)
    assert_instance_of AccessToken, token
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, [ :allow_write_api, :allow_read_gpx ]

    signed_get "/api/0.6/gpx/2", :consumer => client, :token => token
    assert_response :success

    post "/oauth/revoke", :token => token.token
    assert_redirected_to oauth_clients_url(token.user.display_name)
    token = OauthToken.find_by_token(token.token)
    assert_not_nil token.invalidated_at

    signed_get "/api/0.6/gpx/2", :consumer => client, :token => token
    assert_response :unauthorized
  end

  def test_oauth10_desktop_app
    client = client_applications(:oauth_desktop_app)

    post_via_redirect "/login", 
      :username => client.user.email, :password => "test"
    assert_response :success

    signed_get "/oauth/request_token", :consumer => client
    assert_response :success
    token = parse_token(response)
    assert_instance_of RequestToken, token
    assert_not_nil token.created_at
    assert_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, client.permissions

    post "/oauth/authorize", 
      :oauth_token => token.token, 
      :allow_read_prefs => true, :allow_write_prefs => true
    assert_response :success
    assert_template "authorize_success"
    token.reload
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, [ :allow_read_prefs ]

    signed_get "/oauth/access_token", :consumer => client, :token => token
    assert_response :success
    token.reload
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_not_nil token.invalidated_at
    token = parse_token(response)
    assert_instance_of AccessToken, token
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, [ :allow_read_prefs ]

    signed_get "/api/0.6/user/preferences", :consumer => client, :token => token
    assert_response :success

    post "/oauth/revoke", :token => token.token
    assert_redirected_to oauth_clients_url(token.user.display_name)
    token = OauthToken.find_by_token(token.token)
    assert_not_nil token.invalidated_at

    signed_get "/api/0.6/user/preferences", :consumer => client, :token => token
    assert_response :unauthorized
  end

  def test_oauth10a_web_app
    client = client_applications(:oauth_web_app)

    post_via_redirect "/login",
      :username => client.user.email, :password => "test"
    assert_response :success

    signed_get "/oauth/request_token",
      :consumer => client, :oauth_callback => "oob"
    assert_response :success
    token = parse_token(response)
    assert_instance_of RequestToken, token
    assert_not_nil token.created_at
    assert_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, client.permissions

    post "/oauth/authorize",
      :oauth_token => token.token,
      :allow_read_prefs => true, :allow_write_prefs => true
    assert_response :redirect
    verifier = parse_verifier(response)
    assert_redirected_to "http://some.web.app.org/callback?oauth_token=#{token.token}&oauth_verifier=#{verifier}"
    token.reload
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, [ :allow_read_prefs ]

    signed_get "/oauth/access_token", :consumer => client, :token => token
    assert_response :unauthorized

    signed_get "/oauth/access_token",
      :consumer => client, :token => token, :oauth_verifier => verifier
    assert_response :success
    token.reload
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_not_nil token.invalidated_at
    token = parse_token(response)
    assert_instance_of AccessToken, token
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, [ :allow_read_prefs ]

    signed_get "/api/0.6/user/preferences", :consumer => client, :token => token
    assert_response :success

    post "/oauth/revoke", :token => token.token
    assert_redirected_to oauth_clients_url(token.user.display_name)
    token = OauthToken.find_by_token(token.token)
    assert_not_nil token.invalidated_at

    signed_get "/api/0.6/user/preferences", :consumer => client, :token => token
    assert_response :unauthorized

    signed_get "/oauth/request_token",
      :consumer => client,
      :oauth_callback => "http://another.web.app.org/callback"
    assert_response :success
    token = parse_token(response)
    assert_instance_of RequestToken, token
    assert_not_nil token.created_at
    assert_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, client.permissions

    post "/oauth/authorize",
      :oauth_token => token.token,
      :allow_write_api => true, :allow_read_gpx => true
    assert_response :redirect
    verifier = parse_verifier(response)
    assert_redirected_to "http://another.web.app.org/callback?oauth_token=#{token.token}&oauth_verifier=#{verifier}"
    token.reload
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, [ :allow_write_api, :allow_read_gpx ]

    signed_get "/oauth/access_token", :consumer => client, :token => token
    assert_response :unauthorized

    signed_get "/oauth/access_token",
      :consumer => client, :token => token, :oauth_verifier => verifier
    assert_response :success
    token.reload
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_not_nil token.invalidated_at
    token = parse_token(response)
    assert_instance_of AccessToken, token
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, [ :allow_write_api, :allow_read_gpx ]

    signed_get "/api/0.6/gpx/2", :consumer => client, :token => token
    assert_response :success

    post "/oauth/revoke", :token => token.token
    assert_redirected_to oauth_clients_url(token.user.display_name)
    token = OauthToken.find_by_token(token.token)
    assert_not_nil token.invalidated_at

    signed_get "/api/0.6/gpx/2", :consumer => client, :token => token
    assert_response :unauthorized
  end

  def test_oauth10a_desktop_app
    client = client_applications(:oauth_desktop_app)

    post_via_redirect "/login", 
      :username => client.user.email, :password => "test"
    assert_response :success

    signed_get "/oauth/request_token",
      :consumer => client, :oauth_callback => "oob"
    assert_response :success
    token = parse_token(response)
    assert_instance_of RequestToken, token
    assert_not_nil token.created_at
    assert_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, client.permissions

    post "/oauth/authorize", 
      :oauth_token => token.token, 
      :allow_read_prefs => true, :allow_write_prefs => true
    assert_response :success
    assert_template "authorize_success"
    m = response.body.match("<p>The verification code is ([A-Za-z0-9]+)</p>")
    assert_not_nil m
    verifier = m[1]
    token.reload
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, [ :allow_read_prefs ]

    signed_get "/oauth/access_token", :consumer => client, :token => token
    assert_response :unauthorized

    signed_get "/oauth/access_token",
      :consumer => client, :token => token, :oauth_verifier => verifier
    assert_response :success
    token.reload
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_not_nil token.invalidated_at
    token = parse_token(response)
    assert_instance_of AccessToken, token
    assert_not_nil token.created_at
    assert_not_nil token.authorized_at
    assert_nil token.invalidated_at
    assert_allowed token, [ :allow_read_prefs ]

    signed_get "/api/0.6/user/preferences", :consumer => client, :token => token
    assert_response :success

    post "/oauth/revoke", :token => token.token
    assert_redirected_to oauth_clients_url(token.user.display_name)
    token = OauthToken.find_by_token(token.token)
    assert_not_nil token.invalidated_at

    signed_get "/api/0.6/user/preferences", :consumer => client, :token => token
    assert_response :unauthorized
  end

private

  def signed_get(uri, options)
    uri = URI.parse(uri)
    uri.scheme ||= "http"
    uri.host ||= host

    helper = OAuth::Client::Helper.new(nil, options)

    request = OAuth::RequestProxy.proxy(
      "method" => "GET",
      "uri" => uri,
      "parameters" => helper.oauth_parameters
    )

    request.sign!(options)

    get request.signed_uri
  end

  def parse_token(response)
    params = CGI.parse(response.body)

    token = OauthToken.find_by_token(params["oauth_token"].first)
    assert_equal token.secret, params["oauth_token_secret"].first

    token
  end

  def parse_verifier(response)
    params = CGI.parse(URI.parse(response.location).query)

    assert_not_nil params["oauth_verifier"]
    assert params["oauth_verifier"].first.present?

    params["oauth_verifier"].first
  end

  def assert_allowed(token, allowed)
    ClientApplication.all_permissions.each do |p|
      assert_equal allowed.include?(p), token.attributes[p.to_s]
    end
  end
end

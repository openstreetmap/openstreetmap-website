require "test_helper"
require "jwt"

class OAuth2Test < ActionDispatch::IntegrationTest
  def test_oauth2
    user = create(:user)
    client = create(:oauth_application, :redirect_uri => "https://some.web.app.example.org/callback", :scopes => "read_prefs write_api read_gpx")
    state = SecureRandom.urlsafe_base64(16)

    authorize_client(user, client, :state => state)
    assert_response :redirect
    code = validate_redirect(client, state)

    token = request_token(client, code)

    assert_equal "read_prefs", token["scope"]
    test_token(token["access_token"], user, client)
  end

  def test_oauth2_oob
    user = create(:user)
    client = create(:oauth_application, :redirect_uri => "urn:ietf:wg:oauth:2.0:oob", :scopes => "read_prefs write_api read_gpx")

    authorize_client(user, client)
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "oauth2_authorizations/show"
    m = response.body.match(%r{<code id="authorization_code">([A-Za-z0-9_-]+)</code>})
    assert_not_nil m
    code = m[1]

    token = request_token(client, code)

    assert_equal "read_prefs", token["scope"]
    test_token(token["access_token"], user, client)
  end

  def test_oauth2_pkce_plain
    user = create(:user)
    client = create(:oauth_application, :redirect_uri => "https://some.web.app.example.org/callback", :scopes => "read_prefs write_api read_gpx")
    state = SecureRandom.urlsafe_base64(16)
    verifier = SecureRandom.urlsafe_base64(48)
    challenge = verifier

    authorize_client(user, client, :state => state, :code_challenge => challenge, :code_challenge_method => "plain")
    assert_response :redirect
    code = validate_redirect(client, state)

    token = request_token(client, code, verifier)

    assert_equal "read_prefs", token["scope"]
    test_token(token["access_token"], user, client)
  end

  def test_oauth2_pkce_s256
    user = create(:user)
    client = create(:oauth_application, :redirect_uri => "https://some.web.app.example.org/callback", :scopes => "read_prefs write_api read_gpx")
    state = SecureRandom.urlsafe_base64(16)
    verifier = SecureRandom.urlsafe_base64(48)
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), :padding => false)

    authorize_client(user, client, :state => state, :code_challenge => challenge, :code_challenge_method => "S256")
    assert_response :redirect
    code = validate_redirect(client, state)

    token = request_token(client, code, verifier)

    assert_equal "read_prefs", token["scope"]
    test_token(token["access_token"], user, client)
  end

  def test_openid_connect
    user = create(:user)
    client = create(:oauth_application, :redirect_uri => "https://some.web.app.example.org/callback", :scopes => "openid read_prefs")
    state = SecureRandom.urlsafe_base64(16)
    verifier = SecureRandom.urlsafe_base64(48)
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), :padding => false)

    authorize_client(user, client, :state => state, :code_challenge => challenge, :code_challenge_method => "S256", :scope => "openid read_prefs")
    assert_response :redirect
    code = validate_redirect(client, state)

    token = request_token(client, code, verifier)

    assert_equal "openid read_prefs", token["scope"]

    access_token = token["access_token"]
    assert_not_nil access_token

    id_token = token["id_token"]
    assert_not_nil id_token

    data, _headers = JWT.decode id_token, nil, true, {
      :algorithm => [Doorkeeper::OpenidConnect.signing_algorithm.to_s],
      :verify_iss => true,
      :iss => "#{Settings.server_protocol}://#{Settings.server_url}",
      :verify_sub => true,
      :sub => user.id,
      :verify_aud => true,
      :aud => client.uid
    } do |headers, _payload|
      kid = headers["kid"]
      get oauth_discovery_keys_path
      keys = response.parsed_body["keys"]
      jwk = keys&.detect { |e| e["kid"] == kid }
      jwk && JWT::JWK::RSA.import(jwk).public_key
    end

    assert_equal user.id.to_s, data["sub"]
    assert_not data.key?("preferred_username")

    get oauth_userinfo_path
    assert_response :unauthorized

    auth_header = bearer_authorization_header(access_token)
    get oauth_userinfo_path, :headers => auth_header
    assert_response :success

    userinfo = response.parsed_body

    assert_not_nil userinfo
    assert_equal user.id.to_s, userinfo["sub"]
    assert_equal user.display_name, userinfo["preferred_username"]
  end

  def test_openid_discovery
    get oauth_discovery_provider_path
    assert_response :success
    openid_config = response.parsed_body

    assert_equal "#{Settings.server_protocol}://#{Settings.server_url}", openid_config["issuer"]

    assert_equal oauth_authorization_path, URI(openid_config["authorization_endpoint"]).path
    assert_equal oauth_token_path, URI(openid_config["token_endpoint"]).path
    assert_equal oauth_userinfo_path, URI(openid_config["userinfo_endpoint"]).path
    assert_equal oauth_discovery_keys_path, URI(openid_config["jwks_uri"]).path
  end

  def test_openid_key
    get oauth_discovery_keys_path
    assert_response :success
    key_info = response.parsed_body
    assert key_info.key?("keys")
    assert_equal 1, key_info["keys"].size
    assert_equal Doorkeeper::OpenidConnect.signing_key.kid, key_info["keys"][0]["kid"]
  end

  private

  def authorize_client(user, client, options = {})
    options = {
      :client_id => client.uid,
      :redirect_uri => client.redirect_uri,
      :response_type => "code",
      :scope => "read_prefs"
    }.merge(options)

    get oauth_authorization_path(options)
    assert_redirected_to login_path(:referer => request.fullpath)

    post login_path(:username => user.email, :password => "test")
    follow_redirect!
    assert_response :success

    get oauth_authorization_path(options)
    assert_response :success
    assert_template "oauth2_authorizations/new"

    delete oauth_authorization_path(options)

    validate_deny(client, options)

    post oauth_authorization_path(options)
  end

  def validate_deny(client, options)
    if client.redirect_uri == "urn:ietf:wg:oauth:2.0:oob"
      assert_response :bad_request
    else
      assert_response :redirect
      location = URI.parse(response.location)
      assert_match(/^#{Regexp.escape(client.redirect_uri)}/, location.to_s)
      query = Rack::Utils.parse_query(location.query)
      assert_equal "access_denied", query["error"]
      assert_equal "The resource owner or authorization server denied the request.", query["error_description"]
      assert_equal options[:state], query["state"]
    end
  end

  def validate_redirect(client, state)
    location = URI.parse(response.location)
    assert_match(/^#{Regexp.escape(client.redirect_uri)}/, location.to_s)
    query = Rack::Utils.parse_query(location.query)
    assert_equal state, query["state"]

    query["code"]
  end

  def request_token(client, code, verifier = nil)
    options = {
      :client_id => client.uid,
      :client_secret => client.plaintext_secret,
      :code => code,
      :grant_type => "authorization_code",
      :redirect_uri => client.redirect_uri
    }

    if verifier
      post oauth_token_path(options)
      assert_response :bad_request

      options = options.merge(:code_verifier => verifier)
    end

    post oauth_token_path(options)
    assert_response :success
    token = response.parsed_body
    assert_equal "Bearer", token["token_type"]

    token
  end

  def test_token(token, user, client)
    get api_user_preferences_path
    assert_response :unauthorized

    auth_header = bearer_authorization_header(token)

    get api_user_preferences_path, :headers => auth_header
    assert_response :success

    get api_user_preferences_path(:access_token => token)
    assert_response :unauthorized

    get api_user_preferences_path(:bearer_token => token)
    assert_response :unauthorized

    get api_trace_path(:id => 2), :headers => auth_header
    assert_response :forbidden

    user.suspend!

    get api_user_preferences_path, :headers => auth_header
    assert_response :forbidden

    user.hide!

    get api_user_preferences_path, :headers => auth_header
    assert_response :forbidden

    user.unhide!

    get api_user_preferences_path, :headers => auth_header
    assert_response :success

    post oauth_revoke_path(:token => token)
    assert_response :forbidden

    post oauth_revoke_path(:token => token,
                           :client_id => client.uid,
                           :client_secret => client.plaintext_secret)
    assert_response :success

    get api_user_preferences_path, :headers => auth_header
    assert_response :unauthorized
  end
end

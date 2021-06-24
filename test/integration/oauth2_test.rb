require "test_helper"

class OAuth2Test < ActionDispatch::IntegrationTest
  def test_oauth2
    client = create(:oauth_application, :redirect_uri => "https://some.web.app.example.org/callback", :scopes => "read_prefs write_api read_gpx")
    state = SecureRandom.urlsafe_base64(16)

    authorize_client(client, :state => state)
    assert_response :redirect
    code = validate_redirect(client, state)

    token = request_token(client, code)

    test_token(token, client)
  end

  def test_oauth2_oob
    client = create(:oauth_application, :redirect_uri => "urn:ietf:wg:oauth:2.0:oob", :scopes => "read_prefs write_api read_gpx")

    authorize_client(client)
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "oauth2_authorizations/show"
    m = response.body.match(%r{<code id="authorization_code">([A-Za-z0-9_-]+)</code>})
    assert_not_nil m
    code = m[1]

    token = request_token(client, code)

    test_token(token, client)
  end

  def test_oauth2_pkce_plain
    client = create(:oauth_application, :redirect_uri => "https://some.web.app.example.org/callback", :scopes => "read_prefs write_api read_gpx")
    state = SecureRandom.urlsafe_base64(16)
    verifier = SecureRandom.urlsafe_base64(48)
    challenge = verifier

    authorize_client(client, :state => state, :code_challenge => challenge, :code_challenge_method => "plain")
    assert_response :redirect
    code = validate_redirect(client, state)

    token = request_token(client, code, verifier)

    test_token(token, client)
  end

  def test_oauth2_pkce_s256
    client = create(:oauth_application, :redirect_uri => "https://some.web.app.example.org/callback", :scopes => "read_prefs write_api read_gpx")
    state = SecureRandom.urlsafe_base64(16)
    verifier = SecureRandom.urlsafe_base64(48)
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), :padding => false)

    authorize_client(client, :state => state, :code_challenge => challenge, :code_challenge_method => "S256")
    assert_response :redirect
    code = validate_redirect(client, state)

    token = request_token(client, code, verifier)

    test_token(token, client)
  end

  private

  def authorize_client(client, options = {})
    options = options.merge(:client_id => client.uid,
                            :redirect_uri => client.redirect_uri,
                            :response_type => "code",
                            :scope => "read_prefs")

    get oauth_authorization_path(options)
    assert_response :redirect
    assert_redirected_to login_path(:referer => request.fullpath)

    user = create(:user)

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
    token = JSON.parse(response.body)
    assert_equal "Bearer", token["token_type"]
    assert_equal "read_prefs", token["scope"]

    token["access_token"]
  end

  def test_token(token, client)
    get user_preferences_path
    assert_response :unauthorized

    auth_header = bearer_authorization_header(token)

    get user_preferences_path, :headers => auth_header
    assert_response :success

    get user_preferences_path(:access_token => token)
    assert_response :unauthorized

    get user_preferences_path(:bearer_token => token)
    assert_response :unauthorized

    get api_trace_path(:id => 2), :headers => auth_header
    assert_response :forbidden

    post oauth_revoke_path(:token => token)
    assert_response :forbidden

    post oauth_revoke_path(:token => token,
                           :client_id => client.uid,
                           :client_secret => client.plaintext_secret)
    assert_response :success

    get user_preferences_path, :headers => auth_header
    assert_response :unauthorized
  end
end

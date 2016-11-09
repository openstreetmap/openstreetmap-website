require "test_helper"

class UserTermsSeenTest < ActionDispatch::IntegrationTest
  fixtures :users

  def setup
    stub_signup_requests
  end

  def test_api_blocked
    with_terms_seen(true) do
      user = users(:terms_not_seen_user)

      get "/api/#{API_VERSION}/user/preferences", nil, auth_header(user.display_name, "test")
      assert_response :forbidden

      # touch it so that the user has seen the terms
      user.terms_seen = true
      user.save

      get "/api/#{API_VERSION}/user/preferences", nil, auth_header(user.display_name, "test")
      assert_response :success
    end
  end

  def test_terms_presented_at_login
    with_terms_seen(true) do
      user = users(:terms_not_seen_user)

      # try to log in
      get_via_redirect "/login"
      assert_response :success
      assert_template "user/login"
      post "/login", :username => user.email, :password => "test", :referer => "/diary/new"
      assert_response :redirect
      # but now we need to look at the terms
      assert_redirected_to :controller => :user, :action => :terms, :referer => "/diary/new"
      follow_redirect!
      assert_response :success

      # don't agree to the terms, but hit decline
      post "/user/save", :decline => true, :referer => "/diary/new"
      assert_redirected_to "/diary/new"
      follow_redirect!

      # should be carried through to a normal login with a message
      assert_response :success
      assert !flash[:notice].nil?
    end
  end

  def test_terms_cant_be_circumvented
    with_terms_seen(true) do
      user = users(:terms_not_seen_user)

      # try to log in
      get_via_redirect "/login"
      assert_response :success
      assert_template "user/login"
      post "/login", :username => user.email, :password => "test", :referer => "/diary/new"
      assert_response :redirect
      # but now we need to look at the terms
      assert_redirected_to :controller => :user, :action => :terms, :referer => "/diary/new"

      # check that if we go somewhere else now, it redirects
      # back to the terms page.
      get "/traces/mine"
      assert_redirected_to :controller => :user, :action => :terms, :referer => "/traces/mine"
      get "/traces/mine", :referer => "/diary/new"
      assert_redirected_to :controller => :user, :action => :terms, :referer => "/diary/new"
    end
  end

  private

  def auth_header(user, pass)
    { "HTTP_AUTHORIZATION" => format("Basic %s", Base64.encode64("#{user}:#{pass}")) }
  end

  def with_terms_seen(value)
    require_terms_seen = Object.send("remove_const", "REQUIRE_TERMS_SEEN")
    Object.const_set("REQUIRE_TERMS_SEEN", value)

    yield

    Object.send("remove_const", "REQUIRE_TERMS_SEEN")
    Object.const_set("REQUIRE_TERMS_SEEN", require_terms_seen)
  end
end

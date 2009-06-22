require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../oauth_controller_test_helper'
require 'oauth/client/action_controller_request'

class OauthController; def rescue_action(e) raise e end; end

class OauthControllerRequestTokenTest < ActionController::TestCase
  include OAuthControllerTestHelper
  tests OauthController
  
  def setup
    @controller = OauthController.new
    setup_oauth
    sign_request_with_oauth
    @client_application.stubs(:create_request_token).returns(@request_token)
  end
  
  def do_get
    get :request_token
  end
  
  def test_should_be_successful
    do_get
    assert @response.success?
  end
  
  def test_should_query_for_client_application
    ClientApplication.expects(:find_by_key).with('key').returns(@client_application)
    do_get
  end
  
  def test_should_request_token_from_client_application
    @client_application.expects(:create_request_token).returns(@request_token)
    do_get
  end
  
  def test_should_return_token_string
    do_get
    assert_equal @request_token_string, @response.body
  end
end

class OauthControllerTokenAuthorizationTest < ActionController::TestCase
   include OAuthControllerTestHelper
   tests OauthController
   
  def setup
    @controller = OauthController.new
    login
    setup_oauth
    RequestToken.stubs(:find_by_token).returns(@request_token)
  end
  
  def do_get
    get :authorize, :oauth_token => @request_token.token
  end

  def do_post
    @request_token.expects(:authorize!).with(@user)
    post :authorize,:oauth_token=>@request_token.token,:authorize=>"1"
  end

  def do_post_without_user_authorization
    @request_token.expects(:invalidate!)
    post :authorize,:oauth_token=>@request_token.token,:authorize=>"0"
  end

  def do_post_with_callback
    @request_token.expects(:authorize!).with(@user)
    post :authorize,:oauth_token=>@request_token.token,:oauth_callback=>"http://application/alternative",:authorize=>"1"
  end

  def do_post_with_no_application_callback
    @request_token.expects(:authorize!).with(@user)
    @client_application.stubs(:callback_url).returns(nil)
    post :authorize, :oauth_token => @request_token.token, :authorize=>"1"
  end
  
  def test_should_be_successful
    do_get
    assert @response.success?
  end
  
  def test_should_query_for_client_application
    RequestToken.expects(:find_by_token).returns(@request_token)
    do_get
  end
  
  def test_should_assign_token
    do_get
    assert_equal @request_token, assigns(:token)
  end
  
  def test_should_render_authorize_template
    do_get
    assert_template('authorize')
  end
  
  def test_should_redirect_to_default_callback
    do_post
    assert_response :redirect
    assert_redirected_to("http://application/callback?oauth_token=#{@request_token.token}")
  end

  def test_should_redirect_to_callback_in_query
    do_post_with_callback
    assert_response :redirect
    assert_redirected_to("http://application/alternative?oauth_token=#{@request_token.token}")
  end

  def test_should_be_successful_on_authorize_without_any_application_callback
    do_post_with_no_application_callback
    assert @response.success?
    assert_template('authorize_success')
  end
  
  def test_should_render_failure_screen_on_user_invalidation
    do_post_without_user_authorization
    assert_template('authorize_failure')
  end

  def test_should_render_failure_screen_if_token_is_invalidated
    @request_token.expects(:invalidated?).returns(true)
    do_get
    assert_template('authorize_failure')
  end
  

end

class OauthControllerGetAccessTokenTest < ActionController::TestCase
  include OAuthControllerTestHelper
  tests OauthController
  
  def setup
    @controller = OauthController.new
    setup_oauth
    sign_request_with_oauth @request_token
    @request_token.stubs(:exchange!).returns(@access_token)
  end
  
  def do_get
    get :access_token
  end
  
  def test_should_be_successful
    do_get
    assert @response.success?
  end
  
  def test_should_query_for_client_application
    ClientApplication.expects(:find_token).with(@request_token.token).returns(@request_token)
    do_get
  end
  
  def test_should_request_token_from_client_application
    @request_token.expects(:exchange!).returns(@access_token)
    do_get
  end
  
  def test_should__return_token_string
    do_get
    assert_equal @access_token_string, @response.body
  end
end

class OauthorizedController < ApplicationController
  before_filter :login_or_oauth_required,:only=>:both
  before_filter :login_required,:only=>:interactive
  before_filter :oauth_required,:only=>:token_only
    
  def interactive
    render :text => "interactive"
  end
  
  def token_only
    render :text => "token"
  end
  
  def both
    render :text => "both"
  end
end
 

class OauthControllerAccessControlTest < ActionController::TestCase
  include OAuthControllerTestHelper
  tests OauthorizedController
  
  def setup
    @controller = OauthorizedController.new
  end
  
  def test_should__have_access_token_set_up_correctly
    setup_to_authorize_request
    assert @access_token.is_a?(AccessToken)
    assert @access_token.authorized?
    assert !@access_token.invalidated?
    assert_equal @user, @access_token.user
    assert_equal @client_application, @access_token.client_application
  end
  
  def test_should_return_false_for_oauth_by_default
    assert_equal false, @controller.send(:oauth?)
  end

  def test_should_return_nil_for_current_token_by_default
    assert_nil @controller.send(:current_token)
  end
  
  def test_should_allow_oauth_when_using_login_or_oauth_required
    setup_to_authorize_request
    sign_request_with_oauth(@access_token)
    ClientApplication.expects(:find_token).with(@access_token.token).returns(@access_token)
    get :both
    assert_equal @access_token, @controller.send(:current_token)
    assert @controller.send(:current_token).is_a?(AccessToken)
    assert_equal @user, @controller.send(:current_user)
    assert_equal @client_application, @controller.send(:current_client_application)
    assert_equal '200', @response.code
    assert @response.success?
  end

  def test_should_allow_interactive_when_using_login_or_oauth_required
    login
    get :both
    assert @response.success?
    assert_equal @user, @controller.send(:current_user)
    assert_nil @controller.send(:current_token)
  end
  
  def test_should_allow_oauth_when_using_oauth_required
    setup_to_authorize_request
    sign_request_with_oauth(@access_token)
    ClientApplication.expects(:find_token).with(@access_token.token).returns(@access_token)
    get :token_only
    assert_equal @access_token, @controller.send(:current_token)
    assert_equal @client_application, @controller.send(:current_client_application)
    assert_equal @user, @controller.send(:current_user)
    assert_equal '200', @response.code
    assert @response.success? 
  end

  def test_should_disallow_oauth_using_request_token_when_using_oauth_required
    setup_to_authorize_request
    ClientApplication.expects(:find_token).with(@request_token.token).returns(@request_token)
    sign_request_with_oauth(@request_token)
    get :token_only
    assert_equal '401', @response.code
  end

  def test_should_disallow_interactive_when_using_oauth_required
    login
    get :token_only
    assert_equal '401', @response.code
    
    assert_equal @user, @controller.send(:current_user)
    assert_nil @controller.send(:current_token)
  end

  def test_should_disallow_oauth_when_using_login_required
    setup_to_authorize_request
    sign_request_with_oauth(@access_token)
    get :interactive
    assert_equal "302",@response.code
    assert_nil @controller.send(:current_user)
    assert_nil @controller.send(:current_token)
  end

  def test_should_allow_interactive_when_using_login_required
    login
    get :interactive
    assert @response.success?
    assert_equal @user, @controller.send(:current_user)
    assert_nil @controller.send(:current_token)
  end

end

class OauthControllerRevokeTest < ActionController::TestCase
  include OAuthControllerTestHelper
  tests OauthController
  
  def setup
    @controller = OauthController.new
    setup_oauth_for_user
    @request_token.stubs(:invalidate!)
  end
  
  def do_post
    post :revoke, :token => "TOKEN STRING"
  end
  
  def test_should_redirect_to_index
    do_post
    assert_response :redirect
    assert_redirected_to('http://test.host/oauth_clients')
  end
  
  def test_should_query_current_users_tokens
    @tokens.expects(:find_by_token).returns(@request_token)
    do_post
  end
  
  def test_should_call_invalidate_on_token
    @request_token.expects(:invalidate!)
    do_post
  end
  
end

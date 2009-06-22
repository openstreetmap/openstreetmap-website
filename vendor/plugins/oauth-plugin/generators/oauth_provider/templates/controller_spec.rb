require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/oauth_controller_spec_helper'
require 'oauth/client/action_controller_request'

describe OauthController, "getting a request token" do
  include OAuthControllerSpecHelper
  before(:each) do
    setup_oauth
    sign_request_with_oauth
    @client_application.stub!(:create_request_token).and_return(@request_token)
  end
  
  def do_get
    get :request_token
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should query for client_application" do
    ClientApplication.should_receive(:find_by_key).with('key').and_return(@client_application)
    do_get
  end
  
  it "should request token from client_application" do
    @client_application.should_receive(:create_request_token).and_return(@request_token)
    do_get
  end
  
  it "should return token string" do
    do_get
    response.body.should == @request_token_string
  end
end

describe OauthController, "token authorization" do
  include OAuthControllerSpecHelper
  before(:each) do
    login
    setup_oauth
    RequestToken.stub!(:find_by_token).and_return(@request_token)
  end
  
  def do_get
    get :authorize, :oauth_token => @request_token.token
  end

  def do_post
    @request_token.should_receive(:authorize!).with(@user)
    post :authorize, :oauth_token => @request_token.token, :authorize => "1"
  end

  def do_post_without_user_authorization
    @request_token.should_receive(:invalidate!)
    post :authorize, :oauth_token => @request_token.token, :authorize => "0"
  end

  def do_post_with_callback
    @request_token.should_receive(:authorize!).with(@user)
    post :authorize, :oauth_token => @request_token.token, :oauth_callback => "http://application/alternative", :authorize => "1"
  end

  def do_post_with_no_application_callback
    @request_token.should_receive(:authorize!).with(@user)
    @client_application.stub!(:callback_url).and_return(nil)
    post :authorize, :oauth_token => @request_token.token, :authorize => "1"
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should query for client_application" do
    RequestToken.should_receive(:find_by_token).and_return(@request_token)
    do_get
  end
  
  it "should assign token" do
    do_get
    assigns[:token].should equal(@request_token)
  end
  
  it "should render authorize template" do
    do_get
    response.should render_template('authorize')
  end
  
  it "should redirect to default callback" do
    do_post
    response.should be_redirect
    response.should redirect_to("http://application/callback?oauth_token=#{@request_token.token}")
  end

  it "should redirect to callback in query" do
    do_post_with_callback
    response.should be_redirect
    response.should redirect_to("http://application/alternative?oauth_token=#{@request_token.token}")
  end

  it "should be successful on authorize without any application callback" do
    do_post_with_no_application_callback
    response.should be_success
  end

  it "should be successful on authorize without any application callback" do
    do_post_with_no_application_callback
    response.should render_template('authorize_success')
  end
  
  it "should render failure screen on user invalidation" do
    do_post_without_user_authorization
    response.should render_template('authorize_failure')
  end

  it "should render failure screen if token is invalidated" do
    @request_token.should_receive(:invalidated?).and_return(true)
    do_get
    response.should render_template('authorize_failure')
  end
  

end


describe OauthController, "getting an access token" do
  include OAuthControllerSpecHelper
  before(:each) do
    setup_oauth
    sign_request_with_oauth @request_token
    @request_token.stub!(:exchange!).and_return(@access_token)
  end
  
  def do_get
    get :access_token
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should query for client_application" do
    ClientApplication.should_receive(:find_token).with(@request_token.token).and_return(@request_token)
    do_get
  end
  
  it "should request token from client_application" do
    @request_token.should_receive(:exchange!).and_return(@access_token)
    do_get
  end
  
  it "should return token string" do
    do_get
    response.body.should == @access_token_string
  end
end

class OauthorizedController<ApplicationController
  before_filter :login_or_oauth_required, :only => :both
  before_filter :login_required, :only => :interactive
  before_filter :oauth_required, :only => :token_only
  
  def interactive
  end
  
  def token_only
  end
  
  def both
  end
end

describe OauthorizedController, " access control" do
  include OAuthControllerSpecHelper
  
  before(:each) do
  end
  
  it "should have access_token set up correctly" do
    setup_to_authorize_request
    @access_token.is_a?(AccessToken).should == true
    @access_token.should be_authorized
    @access_token.should_not be_invalidated
    @access_token.user.should == @user
    @access_token.client_application.should == @client_application
  end
  
  it "should return false for oauth? by default" do
    controller.send(:oauth?).should == false
  end

  it "should return nil for current_token  by default" do
    controller.send(:current_token).should be_nil
  end
  
  it "should allow oauth when using login_or_oauth_required" do
    setup_to_authorize_request
    sign_request_with_oauth(@access_token)
    ClientApplication.should_receive(:find_token).with(@access_token.token).and_return(@access_token)
    get :both
    controller.send(:current_token).should == @access_token
    controller.send(:current_token).is_a?(AccessToken).should == true 
    controller.send(:current_user).should == @user
    controller.send(:current_client_application).should == @client_application
    response.code.should == '200'
    response.should be_success
  end

  it "should allow interactive when using login_or_oauth_required" do
    login
    get :both
    response.should be_success
    controller.send(:current_user).should == @user
    controller.send(:current_token).should be_nil
  end

  
  it "should allow oauth when using oauth_required" do
    setup_to_authorize_request
    sign_request_with_oauth(@access_token)
    ClientApplication.should_receive(:find_token).with(@access_token.token).and_return(@access_token)
    get :token_only
    controller.send(:current_token).should == @access_token
    controller.send(:current_client_application).should == @client_application
    controller.send(:current_user).should == @user 
    response.code.should == '200' 
    response.should be_success 
  end

  it "should disallow oauth using RequestToken when using oauth_required" do
    setup_to_authorize_request
    ClientApplication.should_receive(:find_token).with(@request_token.token).and_return(@request_token)
    sign_request_with_oauth(@request_token)
    get :token_only
    response.code.should == '401'
  end

  it "should disallow interactive when using oauth_required" do
    login
    get :token_only
    response.code.should == '401'
    
    controller.send(:current_user).should == @user
    controller.send(:current_token).should be_nil
  end

  it "should disallow oauth when using login_required" do
    setup_to_authorize_request
    sign_request_with_oauth(@access_token)
    get :interactive
    response.code.should == "302"
    controller.send(:current_user).should be_nil
    controller.send(:current_token).should be_nil
  end

  it "should allow interactive when using login_required" do
    login
    get :interactive
    response.should be_success
    controller.send(:current_user).should == @user
    controller.send(:current_token).should be_nil
  end

end

describe OauthController, "revoke" do
  include OAuthControllerSpecHelper
  before(:each) do
    setup_oauth_for_user
    @request_token.stub!(:invalidate!)
  end
  
  def do_post
    post :revoke, :token => "TOKEN STRING"
  end
  
  it "should redirect to index" do
    do_post
    response.should be_redirect
    response.should redirect_to('http://test.host/oauth_clients')
  end
  
  it "should query current_users tokens" do
    @tokens.should_receive(:find_by_token).and_return(@request_token)
    do_post
  end
  
  it "should call invalidate on token" do
    @request_token.should_receive(:invalidate!)
    do_post
  end
  
end

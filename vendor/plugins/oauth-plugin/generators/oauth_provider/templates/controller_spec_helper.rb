module OAuthControllerSpecHelper
  def login
    controller.stub!(:local_request?).and_return(true)
    @user = mock_model(User)
    controller.stub!(:current_user).and_return(@user)
    @tokens = []
    @tokens.stub!(:find).and_return(@tokens)
    @user.stub!(:tokens).and_return(@tokens)
    User.stub!(:find_by_id).and_return(@user)
  end
  
  def login_as_application_owner
    login
    @client_application = mock_model(ClientApplication)
    @client_applications = [@client_application]
    
    @user.stub!(:client_applications).and_return(@client_applications)
    @client_applications.stub!(:find).and_return(@client_application)
  end
  
  def setup_oauth
    controller.stub!(:local_request?).and_return(true)
    @user||=mock_model(User)
    
    User.stub!(:find_by_id).and_return(@user)
    
    @server = OAuth::Server.new "http://test.host"
    @consumer = OAuth::Consumer.new('key', 'secret',{:site => "http://test.host"})

    @client_application = mock_model(ClientApplication)
    controller.stub!(:current_client_application).and_return(@client_application)
    ClientApplication.stub!(:find_by_key).and_return(@client_application)
    @client_application.stub!(:key).and_return(@consumer.key)
    @client_application.stub!(:secret).and_return(@consumer.secret)
    @client_application.stub!(:name).and_return("Client Application name")
    @client_application.stub!(:callback_url).and_return("http://application/callback")
    @request_token = mock_model(RequestToken, :token => 'request_token', :client_application => @client_application, :secret => "request_secret", :user => @user)
    @request_token.stub!(:invalidated?).and_return(false)
    ClientApplication.stub!(:find_token).and_return(@request_token)
    
    @request_token_string = "oauth_token = request_token&oauth_token_secret = request_secret"
    @request_token.stub!(:to_query).and_return(@request_token_string)

    @access_token = mock_model(AccessToken, :token => 'access_token', :client_application => @client_application, :secret => "access_secret", :user => @user)
    @access_token.stub!(:invalidated?).and_return(false)
    @access_token.stub!(:authorized?).and_return(true)
    @access_token_string = "oauth_token = access_token&oauth_token_secret = access_secret"
    @access_token.stub!(:to_query).and_return(@access_token_string)

    @client_application.stub!(:authorize_request?).and_return(true)
#    @client_application.stub!(:sign_request_with_oauth_token).and_return(@request_token)
    @client_application.stub!(:exchange_for_access_token).and_return(@access_token)
  end
  
  def setup_oauth_for_user
    login
    setup_oauth
    @tokens = [@request_token]
    @tokens.stub!(:find).and_return(@tokens)
    @tokens.stub!(:find_by_token).and_return(@request_token)
    @user.stub!(:tokens).and_return(@tokens)
  end
  
  def sign_request_with_oauth(token = nil)
    ActionController::TestRequest.use_oauth = true
    @request.configure_oauth(@consumer,token)
  end
    
  def setup_to_authorize_request
    setup_oauth
    OauthToken.stub!(:find_by_token).with( @access_token.token).and_return(@access_token)
    @access_token.stub!(:is_a?).and_return(true)
  end
end
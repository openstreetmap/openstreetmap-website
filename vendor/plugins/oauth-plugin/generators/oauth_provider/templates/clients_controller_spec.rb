require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/oauth_controller_spec_helper'
require 'oauth/client/action_controller_request'

describe OauthClientsController, "index" do
  include OAuthControllerSpecHelper
  before(:each) do
    login_as_application_owner
  end
  
  def do_get
    get :index
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should query current_users client applications" do
    @user.should_receive(:client_applications).and_return(@client_applications)
    do_get
  end
  
  it "should assign client_applications" do
    do_get
    assigns[:client_applications].should equal(@client_applications)
  end
  
  it "should render index template" do
    do_get
    response.should render_template('index')
  end
end

describe OauthClientsController, "show" do
  include OAuthControllerSpecHelper
  before(:each) do
    login_as_application_owner
  end
  
  def do_get
    get :show, :id => '3'
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should query current_users client applications" do
    @user.should_receive(:client_applications).and_return(@client_applications)
    @client_applications.should_receive(:find).with('3').and_return(@client_application)
    do_get
  end
  
  it "should assign client_applications" do
    do_get
    assigns[:client_application].should equal(@client_application)
  end
  
  it "should render show template" do
    do_get
    response.should render_template('show')
  end
  
end

describe OauthClientsController, "new" do
  include OAuthControllerSpecHelper
  before(:each) do
    login_as_application_owner
    ClientApplication.stub!(:new).and_return(@client_application)
  end
  
  def do_get
    get :new
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should assign client_applications" do
    do_get
    assigns[:client_application].should equal(@client_application)
  end
  
  it "should render show template" do
    do_get
    response.should render_template('new')
  end
  
end

describe OauthClientsController, "edit" do
  include OAuthControllerSpecHelper
  before(:each) do
    login_as_application_owner
  end
  
  def do_get
    get :edit, :id => '3'
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should query current_users client applications" do
    @user.should_receive(:client_applications).and_return(@client_applications)
    @client_applications.should_receive(:find).with('3').and_return(@client_application)
    do_get
  end
  
  it "should assign client_applications" do
    do_get
    assigns[:client_application].should equal(@client_application)
  end
  
  it "should render edit template" do
    do_get
    response.should render_template('edit')
  end
  
end

describe OauthClientsController, "create" do
  include OAuthControllerSpecHelper
  
  before(:each) do
    login_as_application_owner
    @client_applications.stub!(:build).and_return(@client_application)
    @client_application.stub!(:save).and_return(true)
  end
  
  def do_valid_post
    @client_application.should_receive(:save).and_return(true)
    post :create, 'client_application'=>{'name' => 'my site'}
  end

  def do_invalid_post
    @client_application.should_receive(:save).and_return(false)
    post :create, :client_application=>{:name => 'my site'}
  end
  
  it "should query current_users client applications" do
    @client_applications.should_receive(:build).and_return(@client_application)
    do_valid_post
  end
  
  it "should redirect to new client_application" do
    do_valid_post
    response.should be_redirect
    response.should redirect_to(:action => "show", :id => @client_application.id)
  end
  
  it "should assign client_applications" do
    do_invalid_post
    assigns[:client_application].should equal(@client_application)
  end
  
  it "should render show template" do
    do_invalid_post
    response.should render_template('new')
  end
end

describe OauthClientsController, "destroy" do
  include OAuthControllerSpecHelper
  before(:each) do
    login_as_application_owner
    @client_application.stub!(:destroy)
  end
  
  def do_delete
    delete :destroy, :id => '3'
  end
    
  it "should query current_users client applications" do
    @user.should_receive(:client_applications).and_return(@client_applications)
    @client_applications.should_receive(:find).with('3').and_return(@client_application)
    do_delete
  end

  it "should destroy client applications" do
    @client_application.should_receive(:destroy)
    do_delete
  end
    
  it "should redirect to list" do
    do_delete
    response.should be_redirect
    response.should redirect_to(:action => 'index')
  end
  
end

describe OauthClientsController, "update" do
  include OAuthControllerSpecHelper
  
  before(:each) do
    login_as_application_owner
  end
  
  def do_valid_update
    @client_application.should_receive(:update_attributes).and_return(true)
    put :update, :id => '1', 'client_application'=>{'name' => 'my site'}
  end

  def do_invalid_update
    @client_application.should_receive(:update_attributes).and_return(false)
    put :update, :id => '1', 'client_application'=>{'name' => 'my site'}
  end
  
  it "should query current_users client applications" do
    @user.should_receive(:client_applications).and_return(@client_applications)
    @client_applications.should_receive(:find).with('1').and_return(@client_application)
    do_valid_update
  end
  
  it "should redirect to new client_application" do
    do_valid_update
    response.should be_redirect
    response.should redirect_to(:action => "show", :id => @client_application.id)
  end
  
  it "should assign client_applications" do
    do_invalid_update
    assigns[:client_application].should equal(@client_application)
  end
  
  it "should render show template" do
    do_invalid_update
    response.should render_template('edit')
  end
end

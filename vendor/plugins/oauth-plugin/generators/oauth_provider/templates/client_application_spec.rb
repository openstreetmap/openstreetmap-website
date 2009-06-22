require File.dirname(__FILE__) + '/../spec_helper'
module OAuthSpecHelpers
  
  def create_consumer
    @consumer = OAuth::Consumer.new(@application.key,@application.secret,
      {
        :site => @application.oauth_server.base_url
      })
  end
  
  def create_test_request
    
  end
  
  def create_oauth_request
    @token = AccessToken.create :client_application => @application, :user => users(:quentin)
    @request = @consumer.create_signed_request(:get, "/hello", @token)
  end
  
  def create_request_token_request
    @request = @consumer.create_signed_request(:get, @application.oauth_server.request_token_path, @token)
  end
  
  def create_access_token_request
    @token = RequestToken.create :client_application => @application
    @request = @consumer.create_signed_request(:get, @application.oauth_server.request_token_path, @token)
  end
  
end

describe ClientApplication do #, :shared => true do
  include OAuthSpecHelpers
  fixtures :users, :client_applications, :oauth_tokens
  before(:each) do
    @application = ClientApplication.create :name => "Agree2", :url => "http://agree2.com", :user => users(:quentin)
    create_consumer
  end

  it "should be valid" do
    @application.should be_valid
  end
  
    
  it "should not have errors" do
    @application.errors.full_messages.should == []
  end
  
  it "should have key and secret" do
    @application.key.should_not be_nil
    @application.secret.should_not be_nil
  end

  it "should have credentials" do
    @application.credentials.should_not be_nil
    @application.credentials.key.should == @application.key
    @application.credentials.secret.should == @application.secret
  end
  
end


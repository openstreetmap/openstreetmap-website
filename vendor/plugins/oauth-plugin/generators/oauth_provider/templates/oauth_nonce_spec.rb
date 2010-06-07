require File.dirname(__FILE__) + '/../spec_helper'
require 'oauth/helper'
describe OauthNonce do
  include OAuth::Helper
  before(:each) do
    @oauth_nonce = OauthNonce.remember(generate_key, Time.now.to_i)
  end

  it "should be valid" do
    @oauth_nonce.should be_valid
  end
  
  it "should not have errors" do
    @oauth_nonce.errors.full_messages.should == []
  end
  
  it "should not be a new record" do
    @oauth_nonce.should_not be_new_record
  end
  
  it "should not allow a second one with the same values" do
    OauthNonce.remember(@oauth_nonce.nonce,@oauth_nonce.timestamp).should == false
  end
end

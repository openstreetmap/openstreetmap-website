require 'oauth/helper'
require File.dirname(__FILE__) + '/../test_helper'

class ClientNoneTest < ActiveSupport::TestCase
  include OAuth::Helper
  
  def setup
    @oauth_nonce = OauthNonce.remember(generate_key,Time.now.to_i)
  end

  def test_should_be_valid
    assert @oauth_nonce.valid?
  end
  
  def test_should_not_have_errors
    assert_equal [], @oauth_nonce.errors.full_messages
  end
  
  def test_should_not_be_a_new_record
    assert !@oauth_nonce.new_record?
  end
  
  def test_shuold_not_allow_a_second_one_with_the_same_values
    assert_equal false, OauthNonce.remember(@oauth_nonce.nonce, @oauth_nonce.timestamp)
  end
end
